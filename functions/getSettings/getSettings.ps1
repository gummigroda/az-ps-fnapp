using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$response = [ordered]@{
    Executed = (Get-Date).ToString('s')
    AppSettingSecret = $env:AppSettingDummySecret
    KeyVaultSecret = $env:KeyVaultDummySecret
    RequestData = $Request
} | ConvertTo-Json

Write-Output ("Called by: [{0}]" -f $Request.Headers.'x-forwarded-for')
Write-Output ("with: [{0}]" -f $Request.Headers.'user-agent')

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $response
})
