# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$uri = ("{0}?code={1}" -f $env:Function_GetSettings_Uri, $env:Function_GetSettings_Code)

try {
    Invoke-RestMethod -Method Get -Uri $uri
}
catch {
    Write-Error $_.Exception | Format-List -Force
    Throw $_.Exception
}