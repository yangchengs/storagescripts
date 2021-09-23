
from azure.storage.fileshare import ShareClient

from queue import Queue
import csv
from datetime import datetime

now = datetime.now()
date_time = now.strftime("%m_%d_%Y_%H_%M_%S")

connection_string = "DefaultEndpointsProtocol=https;AccountName=safortesting123456;AccountKey=6emCpM73EbZhJZtmP5QYHXMeurIzbHwts2BfDe2gy9XcmIcmYhNoLEdPdNiWO609D/YQPEdRVr3gWgarZp7sxA==;EndpointSuffix=core.windows.net"
share_name = "fileshare1"
root_folder = "folder1"
max_depth = -1

share_client = ShareClient.from_connection_string(connection_string, share_name)

q = Queue()
q.put(root_folder)

totalsize = 0
logfile = "log_" + root_folder.replace('/', '_') + "_" + date_time + ".csv"
d = dict()
with open(logfile, 'a', encoding='UTF8', newline='') as f:
    writer = csv.writer(f)
    header = ['Path', 'File Name', 'File Size(Mb)', 'Last Modified', 'Create Time']
    writer.writerow(header)

while not q.empty():
    dir_name = q.get()
    #print("list dir " + dir_name)
    try:
        #sizeofFolder = 0
        for item in list(share_client.list_directories_and_files(dir_name, include=["timestamps", "Etag", "Attributes", "PermissionKey"])):
            print(item)            
            if item["is_directory"]:            
                if len(dir_name) > 0:
                    newpath = dir_name + "/" + item["name"]
                    q.put(newpath)
                else:
                    q.put(item["name"])
            else:
                newpath = dir_name + "/" + item["name"]
                parts = newpath.split('/')
                depth = len(parts)
                if max_depth == -1 or max_depth >= depth:
                    totalsize += item["size"]
                    #sizeofFolder += item["size"]
                    col1 = dir_name + "/" + item["name"]
                    col2 = str(str(round(item["size"]/1024/1024, 2)))
                    col3 = str(item["last_modified"])
                    col4 = str(item["creation_time"])
                    data = [col1, item["name"], col2, col3, col4]
                    print(col1 + "," + col2 + "," + col3 + "," + col4)
                    #print(item)
                    #print(item["last_modified"])
                    try:
                        with open(logfile, 'a', encoding='utf-16', newline='') as f:
                            writer = csv.writer(f)
                            writer.writerow(data)
                    except:
                        pass

                elif max_depth != -1 and max_depth < depth:
                    totalsize += item["size"]
                    key = ""
                    for x in range(max_depth):
                        key = key + parts[x] + "/" 
                    #print("key is")
                    #print(key)

                    if key in d:
                        d[key] += item["size"]
                    else:
                        d[key] = item["size"]                    

    except Exception as e:
        print(e)
        print("Error while list dir: " + dir_name)
        
print(d)
for key in d:
    col1 = key
    col2 = str(round(d[key]/1024/1024, 2))
    data = [col1, col1, col2]
    print(col1 + "," + col2)
    try:
        with open(logfile, 'a', encoding='utf-16', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(data)
    except Exception as e:
        print(e)

print("Total size is " + str(totalsize))
with open(logfile, 'a', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    data = ['total', '', str(round(totalsize/1024/1024, 2))]
    writer.writerow(data)
