# Parse command line parameters
param(
    [Parameter()]
    [string]$Organization,
    
    [Parameter()]
    [string]$Project,
    
    [Parameter()]
    [string]$Workspace,
    
    [Parameter()]
    [string]$SpName,
    
    [Parameter()]
    [string]$Role,
    
    [Parameter()]
    [string]$SubscriptionId
)

# Prompt for any missing required values
if (-not $Organization) {
    $Organization = Read-Host "Please enter the organization name"
}

if (-not $Project) {
    $Project = Read-Host "Please enter the project name"
}

if (-not $Workspace) {
    $Workspace = Read-Host "Please enter the workspace name"
}

if (-not $SpName) {
    $SpName = Read-Host "Please enter the service principal name"
}

# Check if already logged in to Azure CLI
try {
    $null = az account show 2>$null
}
catch {
    Write-Host "Not logged into Azure CLI. Initiating login..."
    try {
        $null = az login --allow-no-subscriptions
    }
    catch {
        Write-Error "Azure login failed"
        exit 1
    }
}

Write-Host "Creating app registration '$SpName'..."
$appId = az ad app create --display-name $SpName --query appId -o tsv 2>$null
$null = az ad sp create --id $appId --query id -o tsv 2>$null | Out-Null
$spId = az ad sp show --id $appId --query id -o tsv 2>$null

foreach ($phase in @("plan", "apply")) {
    Write-Host "Creating federated credential for $phase phase..."
    $subject = "organization:$Organization`:project:$Project`:workspace:$Workspace`:run_phase:$phase"

    $parameters = @{
        name        = "tfc-$phase-federated-credential"
        description = "This is a dynamic credential used by Terraform Cloud as part of the $phase phase."
        issuer      = "https://app.terraform.io"
        subject     = $subject
        audiences   = @("api://AzureADTokenExchange")
    } | ConvertTo-Json

    $null = az ad app federated-credential create --id $appId --parameters $parameters 2>$null
}

if ($Role -and $SubscriptionId) {
    Write-Host "Creating role assignment..."
    try {
        $null = az role assignment create `
            --assignee-object-id $spId `
            --assignee-principal-type ServicePrincipal `
            --role $Role `
            --subscription $SubscriptionId `
            --scope "/subscriptions/$SubscriptionId" 2>$null
    }
    catch {
        Write-Host "Error: Failed to create role assignment. Please verify:"
        Write-Host "- Role name '$Role' exists"
        Write-Host "- Subscription '$SubscriptionId' is valid" 
        Write-Host "- You have sufficient permissions to create role assignments"
        Write-Host "The Service Principal has still been created, but the role assignment failed and should be applied manually."
    }
}

Write-Host "`nAdd the following environment variables to your Terraform Cloud workspace:"
Write-Host "- TFC_AZURE_PROVIDER_AUTH = true"
Write-Host "- TFC_AZURE_RUN_CLIENT_ID = $appId"
