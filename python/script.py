#TODO: down all data from tosdr.org

# Session 1 9-27-21
#TODO: cleaning steps to the data pipeline

# Session 2
#TODO:tokenize the data
#TODO: run bag of words model on

# Session 3
#TODO: run tf idf on the model
#TODO: figuring out how to present the data if were satifies, otherwise we look for more advanced models

# Session 4
#TODO: Pulling down the data

import re
import glob
import json
import nltk

nltk.download('punkt')
from nltk.corpus import stopwords
nltk.download('stopwords')

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression

# print(stopwords.words('english'))
stop_words = set(stopwords.words("english"))
from sklearn.feature_extraction.text import CountVectorizer
from sklearn import metrics

import pandas as pd
from tqdm import tqdm


def retrieve_overall_data_from_json(input_json: dict, slug: str) -> pd.DataFrame:
    """Make dataframe from input dictionary."""
    json_data = input_json["parameters"]
    metadata = json_data["_source"]

    df = pd.DataFrame({
        "slug": [slug],
        "rating": [metadata["rating"][0]],
        "created_at": [metadata["created_at"][0]],
        "updated_at": [metadata["updated_at"][0]],
        "is_comprehensively_reviewed": [
            metadata["is_comprehensively_reviewed"][0]
        ],
    })

    return df


def retrieve_points_data_from_json(input_json: dict, slug: str) -> pd.DataFrame:
    """Get points data from input dictionary."""
    json_data = input_json["parameters"]
    points = json_data["points"]
    df_list = [
        pd.DataFrame({
            "slug": [slug],
            "point_id": [point["id"]],
            "needs_moderation": [point["needsModeration"]],
            "quote_text": [point.get("quote")],  # TODO: check nulls
            "case_id": [point["case"]["id"]],
            "title": [point["case"]["title"]],
            "classification": [point["case"]["classification"]],
            "score": [point["case"]["score"]],
            "created_at": [point["case"]["created_at"]],
            "updated_at": [point["case"]["updated_at"]],
        })
        for point in points
    ]

    if len(df_list) > 0: 
        return pd.concat(df_list).reset_index(drop=True)


def get_all_file_dicts():
    """Collect dicts for all files into a list."""
    all_json_file_paths = glob.glob('data-raw/*.json')
    all_dicts = []
    for file_path in all_json_file_paths:
        with open(file_path, "r", encoding="utf8") as fp:
            file_dict = json.load(fp)
        all_dicts.append(file_dict)

    return all_dicts


def get_slug(input_dict: dict) -> str:
    #the arrow -> tells us the data type that is returned
    """Get slug from input dict, which can have multiple formats."""

    # checks if the parameters is a key in the input dictionary
    if "parameters" in input_dict:

        # checks if the slug is a key in the dictionary input
        if "slug" in input_dict["parameters"]:
            return input_dict["parameters"]["slug"][0]
        # checks if the source exists, and if the slug exists in the source
        elif "_source" in input_dict["parameters"]:
            if "slug" in input_dict["parameters"]["_source"]:
                return input_dict["parameters"]["_source"]["slug"][0]

    else:
        #TODO: investigate further
        # raise ValueError("This" + str(input_dict["parameters"].keys()) + "is formatted differently.")
        print("This is formatted differently.")

def createDataframes() -> dict:
    """create dataframes from JSON data"""

    all_dicts = get_all_file_dicts()
    # print("all dicts:", all_dicts)
    overall_df_list = []
    points_df_list = []
    
    for company_dict in tqdm(all_dicts):
        slug = get_slug(company_dict)

        if "parameters" in company_dict:
            if "_source" in company_dict["parameters"]:
                sub_overall_df = retrieve_overall_data_from_json(company_dict, slug)
                sub_points_df = retrieve_points_data_from_json(company_dict, slug)
                overall_df_list.append(sub_overall_df)
                points_df_list.append(sub_points_df)

    overall_df = pd.concat(overall_df_list).reset_index(drop=True)
    points_df = pd.concat(points_df_list).reset_index(drop=True)
    return {"overall": overall_df, "points": points_df}


def strip_html_tags(html_string) :
    "takes in an html string and returns the string witch certain characters stripped"
    return re.sub("<.*?>", "", str(html_string))

def points_moderation_filter(df):
    "checks if the points column needs moderation"
    return df.loc[df['needs_moderation'] == False]
    
def remove_non_alphanumeric_chars(str):
    return re.sub("[^[:alnum:] ]", "", str)

def clean_points_df(df):
    "for every single row in a dataframe we wanna apply a cleaning step to the quotes column"
    print("The current dimensions before cleaning",df.shape)
    df['quote_text'] = df['quote_text'].apply(strip_html_tags)
    df['quote_text'] = df['quote_text'].apply(remove_non_alphanumeric_chars)
    df['quote_text'] = df['quote_text'].apply(strip_white_space)
    df = filter_neutral_and_blocker(df)
    print("filter neutral and blocker", df.shape)
    df = points_moderation_filter(df)
    print("points moderation filter", df.shape)
    df = remove_empty_quote_text_points(df)
    print("remove empty quote text points", df.shape)
    df = lowercase_text(df)

    return df
    "takes in a df, returns a df with a clean quote text column"
    #C:\Users\jaden\OneDrive\Documents\Coding_Projects>python Terms-and-Conditions-Scrape-R/python/script.py

def remove_empty_quote_text_points(df):
    """returns dataframes that arent blank"""
    return df.loc[df['quote_text'] != ""]

def strip_white_space(str):
    return str.strip()

def lowercase_text(df):
    df['quote_text'] = df['quote_text'].str.lower()
    return df

def return_outcome(df):
    return df["classification"].eq("good").mul(1)


def filter_neutral_and_blocker(df):
    return df[df['classification'].isin(["good", "bad"])]

    
# def tokenize_data(df):
#     df['tokenized'] = df.apply(lambda row: nltk.word_tokenize(row['quote_text']), axis=1)
#     return df

# def filtered_tokenized_data(list):
#     #want it to go through each row of the tokenized column and remove stop words from each value
#     filtered_sentence = [w for w in list if not w.lower() in stop_words]
#     return filtered_sentence

# def apply_filtered_tokenized_data(df):
#     df["tokenized"] = df["tokenized"].apply(filtered_tokenized_data)
#     return df

def count_vectorize(df):
    vectorizer = CountVectorizer() #tokenizes and counts
    x = vectorizer.fit_transform(df["quote_text"]) #returns document term vectorizer matrix
    return x

def model(df, outcome):
    # splitting the bag of words matrix with counts and outcome (good/bad binary) and uses 25% as testing data
    # For the models performance, X_Train is the bag of words matrix thats gonna be used for the models learning
    # 
    X_train, X_test, y_train, y_test = train_test_split(df, outcome, test_size = 0.25, random_state = 0)
    logreg = LogisticRegression()

    # fit the model with data
    logreg.fit(X_train,y_train)
    y_pred=logreg.predict(X_test)

    cnf_matrix = metrics.confusion_matrix(y_test, y_pred)
    print(cnf_matrix)
    print("Accuracy:",metrics.accuracy_score(y_test, y_pred))


def main():
    dfs = createDataframes()
    points_df = clean_points_df(dfs["points"])
    outcome = return_outcome(points_df)
    # filtered_token_data = apply_filtered_tokenized_data(token_data)
    count_vectorizer = count_vectorize(points_df)
    # write code you are running here!!!
    model(count_vectorizer, outcome)

if __name__ == "__main__":
    main()

# Data: "cleaned" terms & conditions text
# Model: Train on our data, and find the right bullet points to attach to a given terms & conditions
    # Labels: "This is good", "This is bad"
    # Good/bad bullet point is a label for terms & conditions
    # You can have more than one label for a given terms & conditions

    # Easiest case is binary labels - good or bad
# Output: generate a bullet list of good and bad points about a terms & conditions

