# Azure Powershell Function App

This repo consists of [templates](templates/) to deploy a Powershell function App (Consumption PLAN), with a backed Key Vault for storage of secrets.  

It's configured to use a managed identity for the connection to the storage account's file share (Preview), this is used for queues, blobs and tables, etc...

In the [functions](functions/) folder, there is example code for powershell functions showing retrieval of AppSettings from Key Vault.
