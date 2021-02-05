# The OPP-115 corpus can be downloaded at
# https://usableprivacy.org/static/data/OPP-115_v1_0.zip
# Here we parse some annotations and do some exploratory analysis.


# Clear the environment
rm(list=ls())

library(jsonlite)


# Set working directory to your local copy of the OPP-115 dataset, or else
# modify path_to_annotations to reference your local copy.
path_to_annotations = file.path("OPP-115", "annotations")
annotations_files = Sys.glob(file.path(path_to_annotations, "*.csv"))


read_annotation_file = function(file_path) {
  # Read annotation file
  annotation_columns = c(  # see more information in documentation/manual.txt
    "annotation_id",
    "batch_id",
    "annotator_id",
    "policy_id",
    "segment_id",
    "category_name",
    "attributes",
    "policy_url",
    "date"
  )
  annotations = read.csv(
    sample_annotation_file, header=FALSE, col.names=annotation_columns
  )
  return(annotations)
}


flatten_attributes = function(attributes_string) {
  # Flatten a JSON string of attributes into a data-frame.
  # This function discards some information, including the start and end
  # indices of the text, and any attribute with start or end indices of -1.
  # The output of this function is a data.frame with columns
  # text | attribute | value
  # TODO: this can likely be made more concise and efficient with dplyr
  attributes_list = fromJSON(attributes_string)
  result = c()
  for (attribute in names(attributes_list)) {
    attribute_values = attributes_list[[attribute]]
    start_index = attribute_values$startIndexInSegment
    end_index = attribute_values$endIndexInSegment
    if ((start_index == -1) | (end_index == -1)) {
      next
    }
    row = data.frame(
      attribute=attribute,
      text=attributes_list[[attribute]]$selectedText,
      value=attributes_list[[attribute]]$value
    )
    result = rbind(result, row)
  }
  return(rbind(result))
}


flatten_annotations = function(annotations) {
  # Expand data.frame of annotations.
  # For each annotation, this function produces one row per attribute.
  result = c()
  for (i in 1:nrow(annotations)) {
    df = flatten_attributes(annotations$attributes[i])
    df$category_name = annotations$category_name[i]
    df$annotation_id = annotations$annotation_id[i]
    result = rbind(result, df)
  }
  df = rbind(result)
  return(df[,c("annotation_id", "category_name", "text", "attribute", "value")])
}

sample_annotation_file = annotations_files[1]
annotations = read_annotation_file(sample_annotation_file)
df = flatten_annotations(annotations)

# Histogram of annotation categories
barplot(table(df$category_name), las=2)
