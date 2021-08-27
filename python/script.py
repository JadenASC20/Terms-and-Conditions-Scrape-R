import glob
import json

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

    return pd.concat(df_list).reset_index(drop=True)


def get_all_file_dicts() -> None:
    """Collect dicts for all files into a list."""
    all_json_file_paths = glob.glob('data-raw/*.json')
    all_dicts = []
    for file_path in all_json_file_paths:
        with open(file_path, "r") as fp:
            file_dict = json.load(fp)
        all_dicts.append(file_dict)

    return all_dicts


def get_slug(input_dict: dict) -> str:
    """Get slug from input dict, which can have multiple formats."""

    if "slug" in input_dict["parameters"].keys():
        return input_dict["parameters"]["slug"][0]
    elif "slug" in input_dict["parameters"]["_source"].keys():
        return input_dict["parameters"]["_source"]["slug"][0]
    else:
        raise ValueError("This dict is formatted differently.")


def main():
    all_dicts = get_all_file_dicts()

    overall_df_list = []
    points_df_list = []
    for company_dict in tqdm(all_dicts):
        slug = get_slug(company_dict)
        if "_source" in company_dict["parameters"]:
            sub_overall_df = retrieve_overall_data_from_json(company_dict, slug)
            sub_points_df = retrieve_points_data_from_json(company_dict, slug)
            overall_df_list.append(sub_overall_df)
            points_df_list.append(sub_points_df)

    overall_df = pd.concat(overall_df_list).reset_index(drop=True)
    points_df = pd.concat(points_df_list).reset_index(drop=True)

    print(points_df.head())


if __name__ == "__main__":
    main()

"""
for (json in all_json_data) {
  slug <- json$parameters$`_source`$slug[[1]]
  list_of_overall_dfs[[slug]] <- retrieve_overall_data_from_json(json)
  list_of_point_dfs[[slug]] <- retrieve_points_data_from_json(json, slug)
}
overall_df <-
  map_df(list_of_overall_dfs, function(df) {
    df
  })
points_df <-
  map_df(list_of_point_dfs, function(df) {
    df
  })
"""
