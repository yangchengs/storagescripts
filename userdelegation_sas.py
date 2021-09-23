import adal

# Tenant ID for your Azure Subscription
TENANT_ID = '72f988bf-86f1-41af-91ab-2d7cd011db47'

# Your Service Principal App ID
CLIENT = 'ce075c26-d6af-4fc6-806d-2f4fb9a2b47b'

# Your Service Principal Password
KEY = 'r_W7Q~eRB2f3a5IwHJAa1ty8Jrhp81NYG~tJf'

subscription_id = '79ed831f-c7b8-402e-a226-de8aa5f4764a'

STORAGE_ACCOUNT_NAME = "safortesting123456"
CONTAINER_NAME = "mycontainer"
FILE_NAME = "syslog" 

DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ'

authority_url = 'https://login.microsoftonline.com/'+TENANT_ID
context = adal.AuthenticationContext(authority_url)
token = context.acquire_token_with_client_credentials(
    resource='https://storage.azure.com/',
    client_id=CLIENT,
    client_secret=KEY
)

import urllib3
from datetime import datetime, timedelta

now = datetime.utcnow()
now_add_7_days = now + timedelta(days=7)

encoded_body = '<?xml version="1.0" encoding="utf-8"?><KeyInfo><Start>{0}</Start><Expiry>{1}</Expiry></KeyInfo>'.format(now.strftime(DATETIME_FORMAT), now_add_7_days.strftime(DATETIME_FORMAT))

http = urllib3.PoolManager()

auth = 'Bearer ' + token['accessToken']

#print(auth)

URL_User_Delegation = 'https://{0}.blob.core.windows.net/?restype=service&comp=userdelegationkey'.format(STORAGE_ACCOUNT_NAME)

r = http.request('POST', URL_User_Delegation,
                 headers={'Content-Type':'application/xml',
                 'Authorization':auth,
                 'x-ms-version':'2019-12-12'},
                 body=encoded_body)

print("Status code:" + str(r.status))
print(r.data)

body = str(r.data, 'UTF-8')

from datetime import datetime, timedelta
from azure.storage.blob import ResourceTypes, AccountSasPermissions, generate_container_sas, UserDelegationKey, generate_blob_sas

import xml.etree.ElementTree as ET
index = body.index("<UserDelegationKey>")

root = ET.fromstring(body[index:])

ukey = UserDelegationKey()
ukey.signed_expiry = root.find('SignedExpiry').text
ukey.signed_oid = root.find('SignedOid').text
ukey.signed_service = root.find('SignedService').text
ukey.signed_start = root.find('SignedStart').text
ukey.signed_tid = root.find('SignedTid').text
ukey.signed_version = root.find('SignedVersion').text
ukey.value = root.find('Value').text

sas_token_container = generate_container_sas(
    STORAGE_ACCOUNT_NAME,
    CONTAINER_NAME,
    #"readme.txt",
    user_delegation_key=ukey,
    permission=AccountSasPermissions(read=True, write=True, delete=True, list=True),
    expiry=datetime.utcnow() + timedelta(hours=1)
)

print("sas token container:" + sas_token_container)

# Sample of list container
list_url = 'https://{0}.blob.core.windows.net/{1}?restype=container&comp=list&{2}'.format(STORAGE_ACCOUNT_NAME, CONTAINER_NAME, sas_token_container)

print(list_url)

sas_token_blob = generate_blob_sas(
    STORAGE_ACCOUNT_NAME,
    CONTAINER_NAME,
    FILE_NAME,
    user_delegation_key=ukey,
    permission=AccountSasPermissions(read=True, write=True, delete=True, list=True),
    expiry=datetime.utcnow() + timedelta(hours=1)
)

readblob_url = 'https://{0}.blob.core.windows.net/{1}/{2}?{3}'.format(STORAGE_ACCOUNT_NAME, CONTAINER_NAME, FILE_NAME, sas_token_blob)

print(readblob_url)
