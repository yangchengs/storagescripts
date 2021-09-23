###
## DISCLAIMER : This is a sample and is provided as is with no warranties express or implied.
##
###

[CmdletBinding(DefaultParametersetName="SharedKey")]
param(

  [Parameter(Mandatory=$true, HelpMessage="Storage Account Name")] 
  [String] $storage_account_name,

  [Parameter(Mandatory=$true, HelpMessage="Any one of the two shared access keys", ParameterSetName="SharedKey", Position=1)] 
  [String] $storage_shared_key,
  
  [Parameter(Mandatory=$true, HelpMessage="SAS Token : the GET parameters", ParameterSetName="SASToken", Position=1)] 
  [String] $storage_sas_token,
  
  [Parameter(Mandatory=$true, HelpMessage="Container Name", Position=2)] 
  [String] $container_name,

  [Parameter(Mandatory=$false, HelpMessage="Folder Name", Position=3)] 
  [String] $folder_name
)

$containerstats = @()
$output = "c:\output"
$outfile = "c:\output\log.txt"

If ($PsCmdlet.ParameterSetName -eq "SharedKey")
{
  $Ctx = New-AzStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_shared_key
}
Else
{
  $Ctx = New-AzStorageContext -StorageAccountName $storage_account_name -SasToken $storage_sas_token
}

$container_continuation_token = $null

do {

  $containers = Get-AzStorageContainer -Context $Ctx -MaxCount 1 -ContinuationToken $container_continuation_token
        
  $container_continuation_token = $null;
  
  if ($containers -ne $null)
  {
    $container_continuation_token = $containers[$containers.Count - 1].ContinuationToken

    for ([int] $c = 0; $c -lt $containers.Count; $c++)
    {
      $container = $containers[$c].Name

      if (($container_name -ne $null) -and (-not ($container_name -like $container)))
      {
        continue
      }

      Write-Host "Processing container : $container"

      $total_usage = 0
      $total_blob_count = 0
      $soft_delete_usage = 0
      $soft_delete_count = 0
                
      $blob_continuation_token = $null
      $filestats = @()

      do {
        
        if ($folder_name -eq $null)
        {
          $blobs = Get-AzStorageBlob -Context $Ctx -Container $container -MaxCount 5000 -IncludeDeleted -ContinuationToken $blob_continuation_token
        }
        else {
          $blobs = Get-AzStorageBlob -Context $Ctx -Container $container -MaxCount 5000 -IncludeDeleted -ContinuationToken $blob_continuation_token -Prefix $folder_name
        }      

        $blob_continuation_token = $null;

        if ($blobs -ne $null)
        {
          $blob_continuation_token = $blobs[$blobs.Count - 1].ContinuationToken          

          for ([int] $b = 0; $b -lt $blobs.Count; $b++)
          {
            $total_blob_count++
            $total_usage += $blobs[$b].Length
            if ($blobs[$b].IsDeleted)
            {
              $soft_delete_count++
              $soft_delete_usage += $blobs[$b].Length
            }

            $logline  = $blobs[$b].Name + "|" + $blobs[$b].Length + "|" + $blobs[$b].LastModified
            $logline | out-file -Filepath $outfile -append

            $filestats += [PSCustomObject] @{ 
              Name = $blobs[$b].Name 
              Length = $blobs[$b].Length
              LastModified = $blobs[$b].LastModified              
            }
          }

          #$filestats | Format-Table -AutoSize 
          #log $filestats
          If ($blob_continuation_token -ne $null)
          {
            Write-Verbose "Blob listing continuation token = {0}".Replace("{0}",$blob_continuation_token.NextMarker)
          }
        }
      } while ($blob_continuation_token -ne $null)

      Write-Verbose "Calculated size of $container = $total_usage with soft_delete usage of $soft_delete_usage"
                        
      $containerstats += [PSCustomObject] @{ 
        Name = $container 
        TotalBlobCount = $total_blob_count 
        TotalBlobUsage = $total_usage 
        SoftDeletedBlobCount = $soft_delete_count 
        SoftDeletedBlobUsage = $soft_delete_usage 
      }
      $folder_name2 = $folder_name.Replace("/", "_")
      $outputPath = $output + "\BlobFiles_" + $folder_name2 + ".csv"
      $filestats | Export-Csv -Path $outputPath
      $outputPath2 = $output + "\PathFiles_" + $folder_name2 + ".csv"
      $containerstats | Export-Csv -Path $outputPath2
    }
  }
 
  If ($container_continuation_token -ne $null)
  {
    Write-Verbose "Container listing continuation token = {0}".Replace("{0}",$container_continuation_token.NextMarker)
  }

} while ($container_continuation_token -ne $null)


Write-Host "Total container stats"
$containerstats | Format-Table -AutoSize 
