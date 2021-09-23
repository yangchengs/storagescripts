from azure.data.tables import TableClient
from azure.core.exceptions import HttpResponseError
from datetime import timedelta, datetime

connection_string = "DefaultEndpointsProtocol=https;AccountName=safortesting123456;AccountKey=6emCpM73EbZhJZtmP5QYHXMeurIzbHwts2BfDe2gy9XcmIcmYhNoLEdPdNiWO609D/YQPEdRVr3gWgarZp7sxA==;EndpointSuffix=core.windows.net"
table_name = "table1"
table_client = TableClient.from_connection_string(connection_string, table_name)
# [START query_entities]

try:
    daysago = datetime.utcnow() + timedelta(days=30)
    filter_string = "Timestamp le datetime'{}'".format(daysago.strftime("%Y-%m-%dT%H:%M:%SZ"))
    
    count = 0
    print("filter string is {}".format(filter_string))
    
    print("Query entity start")
    pagecount = 0
    for entity_page in table_client.query_entities(filter_string, results_per_page=1000).by_page():
        pagecount+=1
        print("Page number {}".format(pagecount))
        for ent in entity_page:
            try:
                count += 1
                rowkey = ent["RowKey"]
                partitionkey = ent["PartitionKey"]
                table_client.delete_entity(
                    partitionkey,
                    rowkey
                )
                print("Successfully deleted! {0}, {1}, {2}".format(table_name, rowkey, partitionkey))
            except ResourceNotFoundError:
                print("Entity does not exists")
    print("Query entity end")
except HttpResponseError as e:
    print(e.message)
# [END query_entities]

finally:
    pass

    