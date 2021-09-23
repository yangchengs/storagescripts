[CmdletBinding()]
param (
    # Storage Account Name
    [Parameter(Mandatory)]
    [string]
    $StorageAccountName,
	[Parameter(Mandatory)]
    [string]
    $storage_shared_key,
    # Filesystem/Container name
    [Parameter(Mandatory)]
    [string]
    $FileSystem,
    # Root filesystem path
    [Parameter(Mandatory)]
    [string]
    $RootPath
)
begin {
  $FolderSizes = [System.Collections.ArrayList]::Synchronized( `
    (New-Object System.Collections.ArrayList))
}
process {

  $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storage_shared_key

  $dirlist = Get-AzDataLakeGen2ChildItem -Context $ctx -FileSystem $FileSystem -Path $RootPath | Select-Object Path
  $dirlist
  $MaxReturn = 3000
  $dirlist | Foreach-Object -Parallel {
    $MaxReturn = $using:MaxReturn
    $FolderSizes = $using:FolderSizes
    $FileSystem = $using:FileSystem
    $ctx = $using:ctx 
    $Total = 0
    $Count = 0
    $Token = $null
	$output = "c:\output\"
    do {
      $filelist = Get-AzDataLakeGen2ChildItem -Context $ctx -FileSystem $FileSystem -Recurse -MaxCount $MaxReturn -Path $_.Path -ContinuationToken $Token | Where-Object IsDirectory -eq $false
      $Stats = $filelist | Measure-Object -Property Length -Sum
      $Total += $Stats.Sum
      $Count += $Stats.Count
      $Token = $filelist[$filelist.Count -1].ContinuationToken
    } While ($Token -ne $null)
    $Result = [PSCustomObject]@{
      Path = $_.Path
      Size = $Total
      Count = $Count
      Date = (Get-Date)
    }
    #$FolderSizes.Add(@($Result)) | Out-Null
    Write-Host $Result
	$folder_name2 = $_.Path.Replace("/", "_")
    $outputPath = $output + "\BlobFiles_" + $folder_name2 + ".csv"
    $Result | Export-Csv -Path $outputPath
  }
}