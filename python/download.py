# get_all_services_JSON <- function() {
  
#   all_services_json <- load_json("https://api.tosdr.org/all-services/v1/", "all_services.json")
#   all_services_json_clean <- all_services_json[[3]][[2]]
  
#   json_list <- list() # to store results of load_json
#   for (i in 1:length(all_services_json_clean)) {
#     service_slug <- all_services_json_clean[[i]]$slug
#     service_name_json <- paste("https://api.tosdr.org/rest-service/v1/", service_slug, ".json", sep = "")
#     json_list[[service_slug]] <- 
#       tryCatch({
#         load_json(service_name_json, paste(service_slug, ".json", sep = ""))   
#       },
#       catch = function(error) {
#         write_out_json_load_error(service_name_json, error)
#         NA
#       })
#   }
  
#   return(json_list)
# }

import urllib.request, json 
import ssl
from tqdm import tqdm

#TODO: use new url for download.py and encorporate pagination if present,
#TODO: maybe only download data from the last modified date, like a functiont that checks if it needs to update

def download_data():
    ssl._create_default_https_context = ssl._create_unverified_context
    with urllib.request.urlopen("http://api.tosdr.org/all-services/v1/") as url:
        all_services = json.loads(url.read().decode())["parameters"]["services"]

    for service in tqdm(all_services):
        slug = service["slug"]
        endpoint = "https://api.tosdr.org/rest-service/v1/" + slug + ".json"
        try:
            with urllib.request.urlopen(endpoint) as url:
                service_json = json.loads(url.read().decode())
                with open("data-raw/" + slug + ".json", 'w', encoding='utf-8') as f:
                    json.dump(service_json, f, ensure_ascii=False, indent=4)

        except:
            print("ERROR OCURRED!!!!")
            print(endpoint)
            with open('error.txt', 'a') as the_file:
                the_file.write(endpoint)          
if __name__ == "__main__":
    download_data() 