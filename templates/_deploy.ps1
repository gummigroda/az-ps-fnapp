$props = @{
    Name                    = 'az-fnapp' # deployment name
    Location                = 'northeurope'
    TemplateFile            = './main.bicep'
    appName                 = 'azlostfnapp'
    hostingPlanName         = 'pwshPlan'
    resourceGroupName       = 'azlost-fnappdemo-rg'
    region                  = 'northeurope'
    keyVaultAdminsGroupGuid = 'd5f52b85-e12d-477d-87d1-61c3413834a6'
    WhatIf                  = $false
}

New-AzDeployment @props