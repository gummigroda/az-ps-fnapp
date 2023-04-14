# Azure Powershell Function App

This repo consists of [templates](templates/) to deploy a Powershell function App (Consumption PLAN), with a backed Key Vault for storage of secrets.  

It's configured to use a managed identity for the connection to the storage account's file share (Preview), this is used for queues, blobs and tables, etc...

In the [functions](functions/) folder, there is example code for powershell functions showing retrieval of AppSettings from Key Vault.

> To get the `timerFunction` execute without any errors, a change is needed to the setting `Function_GetSettings_Code`. This needs to be set to the Key Vault reference for the function key, i.e. __@Microsoft.KeyVault(SecretUri=https://yourAppName.vault.azure.net/secrets/function--getsettings--default)__
