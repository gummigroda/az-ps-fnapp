using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$response = @{
    AppSettingSecret = $env:AppSettingDummySecret
    KeyVaultSecret = $env:KeyVaultDummySecret
} | ConvertTo-Json

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $response
})
