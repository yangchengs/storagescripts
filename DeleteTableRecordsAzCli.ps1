$accessKey = "6emCpM73EbZhJZtmP5QYHXMeurIzbHwts2BfDe2gy9XcmIcmYhNoLEdPdNiWO609D/YQPEdRVr3gWgarZp7sxA=="
$storageAccount = "safortesting123456"
$ctx = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $accessKey
$tables = Get-AzStorageTable -Context $ctx | Select-object Name

$tables | Foreach-Object {
    $tableName = $_.Name
    if($tableName.StartsWith('WADMetrics','CurrentCultureIgnoreCase')) {
        $msg = "Delete data in table " + $tableName
        Write-Host $msg
        $cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable
        $today = Get-Date
        $daysago = $today.AddDays(-30)
        $dateString = $daysago.ToString("yyyy-MM-ddTHH:mm:ssZ")
        $filter = "(Timestamp le datetime'{0}')" -f $dateString
        $filter

        # Retrieve entity to be deleted, then pipe it into the remove cmdlet.
        Write-Host "To be deleted."
        $entityToDelete = Get-AzTableRow -table $cloudTable -customFilter $filter
        $entityToDelete | Remove-AzTableRow -table $cloudTable
    }
    else {
        $msg = "Do not delete data in table " + $tableName
        Write-Host $msg
    }
}