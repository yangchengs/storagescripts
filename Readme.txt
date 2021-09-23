1. Cx wants to delete old records in storage table because there is no retention setting.
[TBD]: Parallel

2. Get size of storage account.
.\GetContainerUsage.ps1 -storage_account_name safortesting123456 -storage_shared_key "6emCpM73EbZhJZtmP5QYHXMeurIzbHwts2BfDe2gy9XcmIcmYhNoLEdPdNiWO609D/YQPEdRVr3gWgarZp7sxA==" -container_name mycontainer

.\GetContainerUsage.ps1 -storage_account_name safortesting123456 -storage_shared_key "6emCpM73EbZhJZtmP5QYHXMeurIzbHwts2BfDe2gy9XcmIcmYhNoLEdPdNiWO609D/YQPEdRVr3gWgarZp7sxA==" -container_name mycontainer -folder_name dir1

.\GetContainerUsageMultiThread.ps1 -StorageAccountName safortesting123456 -storage_shared_key "6emCpM73EbZhJZtmP5QYHXMeurIzbHwts2BfDe2gy9XcmIcmYhNoLEdPdNiWO609D/YQPEdRVr3gWgarZp7sxA==" -FileSystem mycontainer -RootPath "/"