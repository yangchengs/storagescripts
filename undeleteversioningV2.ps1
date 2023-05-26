$access_key = "3oTeTC/FRSU/C60jsURI7zYNOvyyiCaRC7rWW4KzZaH6ZDZA0eS94EMI+f1IxRG9+pLfo+BavZd9+AStIZj6YA=="
$storage_account_name = "yangshentest09a"
$container_name = "hdpdv4"

$Ctx = New-AzStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $access_key
# candidatesHashtable contains all the versioned files
# and it only has the latest version
$candidates = @()
$Total = 0
$Token = $Null
$MaxReturn = 5000

do
{
    "Loop $MaxReturn"
    $blobs = Get-AzStorageBlob -Context $Ctx -Container $container_name -MaxCount $MaxReturn -IncludeVersion -ContinuationToken $Token | where-object { !$_.IsLatestVersion }
    $candidates += $blobs
    $Total += $blobs.Count
    if($blobs.Length -le 0) 
    { 
        Break;
    }
    $Token = $blobs[$blobs.Count -1].ContinuationToken;
}
While ($Null -ne $Token)
$candidates

$candidatesHashtable = @{}
foreach($candidate in $candidates) {

    $candidatesHashtable[$candidate.Name] = $candidate
}
$candidatesHashtable

# existingBlobshashtable contains the currrent files.
$Total = 0
$Token = $Null
$existingBlobshashtable = @{}
do
 {
    "Loop $MaxReturn"
    $blobs = Get-AzStorageBlob -Context $Ctx -Container $container_name -MaxCount $MaxReturn -ContinuationToken $Token
    $existingBlobs += $blobs
    $Total += $blobs.Count
    if($blobs.Length -le 0) 
    { 
        Break;
    }
    $Token = $blobs[$blobs.Count -1].ContinuationToken;
 }
 While ($Null -ne $Token)
  
$existingBlobs
foreach ($existingBlob in $existingBlobs) {
    $existingBlobshashtable[$existingBlob.Name] = $existingBlob.BlobName
}

foreach($key in $candidatesHashtable.keys) {  
    if ($existingBlobshashtable.ContainsKey($key)) {
        "$key was not deleted"
    } 
    else {
        "$key was deleted"
        "undelete it now"

        # Powershell v7 converts the version id to datetime object so that we have to change it back to string
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $versionString = $candidatesHashtable[$key].versionId.ToString("o")
        }
    
        if ($PSVersionTable.PSVersion.Major -le 5) {
            $versionString = $candidatesHashtable[$key].versionId
        }

        $uri =  "https://" + $storage_account_name + ".blob.core.windows.net/" + $container_name + "/" + $key + "?versionId=" + $versionString
        $uri
        #az storage blob copy start --account-name $storage_account_name --destination-blob $key --destination-container $container_name --account-key $access_key --source-uri $uri
        
        $srcBlob = Get-AzStorageBlob -Container $container_name -Blob $key -VersionId $versionString -Context $Ctx 
        #$destBlob =  $srcBlob | Copy-AzStorageBlob  -DestContainer $container_name -DestBlob $key
        $destBlob =  $srcBlob | Start-AzStorageBlobCopy  -DestContainer $container_name -DestBlob $key
    } 
}