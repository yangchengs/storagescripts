$access_key = "5ZSU49HqeatlNJXXuQbzblziehMXvkeGr6z1WrqiSvRZDpoV5PBUuRLc2jquU2U9GySG/on5pT3jJFOlkie56A=="
$storage_account_name = "yangshendls004"
$container_name = "dir8"

# candidatesHashtable contains all the versioned files
# and it only has the latest version
$candidates = (az storage blob list --container-name $container_name --account-key $access_key --account-name $storage_account_name --include "dv" --query "[?(!isCurrentVersion||deleted)].{BlobName:name, DeleteTime:properties.deletedTime,isCurrentVersion:isCurrentVersion, versionId:versionId}" --output json)  | ConvertFrom-Json 
$candidates

$candidatesHashtable = @{}
foreach($candidate in $candidates) {

    $candidatesHashtable[$candidate.BlobName] = $candidate
}
$candidatesHashtable

# existingBlobshashtable contains the currrent files.
$existingBlobshashtable = @{}
$existingBlobs = (az storage blob list --container-name $container_name --account-key $access_key --account-name $storage_account_name --include "dv" --query "[?(isCurrentVersion)].{BlobName:name, DeleteTime:properties.deletedTime,isCurrentVersion:isCurrentVersion, versionId:versionId}" --output json) | ConvertFrom-Json  
$existingBlobs
foreach ($existingBlob in $existingBlobs) {
    $existingBlobshashtable[$existingBlob.BlobName] = $existingBlob.BlobName
}

foreach($key in $candidatesHashtable.keys) {  
    if ($existingBlobshashtable.ContainsKey($key)) {
        "$key is not deleted"
    } 
    else {
        "$key is deleted"
        "undelete it now"

        # Powershell v7 converts the version id to datetime object so that we have to change it back to string
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $versionString = $candidatesHashtable[$key].versionId.ToString("o")
        }
    
        if ($PSVersionTable.PSVersion.Major -le 5) {
            $versionString = $candidatesHashtable[$key].versionId
        }

        az storage blob undelete --container-name $container_name --name $key --account-key $access_key --account-name $storage_account_name

        $uri =  "https://" + $storage_account_name + ".blob.core.windows.net/" + $container_name + "/" + $key + "?versionId=" + $versionString
        $uri
        az storage blob copy start --account-name $storage_account_name --destination-blob $key --destination-container $container_name --account-key $access_key --source-uri $uri
    } 
}