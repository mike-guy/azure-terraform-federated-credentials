#!/bin/bash

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--organization)
      organization="$2"
      shift 2
      ;;
    -p|--project)
      project="$2" 
      shift 2
      ;;
    -w|--workspace)
      workspace="$2"
      shift 2
      ;;
    -s|--sp-name)
      sp_name="$2"
      shift 2
      ;;
    -r|--role)
      role="$2"
      shift 2
      ;;
    --subscription-id)
      subscription_id="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Prompt for any missing required values
if [ -z "$organization" ]; then
  read -p "Please enter the organization name: " organization
fi

if [ -z "$project" ]; then
  read -p "Please enter the project name: " project
fi

if [ -z "$workspace" ]; then
  read -p "Please enter the workspace name: " workspace
fi

if [ -z "$sp_name" ]; then
  read -p "Please enter the service principal name: " sp_name
fi

# Check if already logged in to Azure CLI
if ! az account show &>/dev/null; then
  echo "Not logged into Azure CLI. Initiating login..."
  az login --allow-no-subscriptions|| { echo "Azure login failed"; exit 1; }
fi

echo "Creating app registration '$sp_name'..."
app_id=$(az ad app create --display-name "$sp_name" --query appId -o tsv 2>/dev/null)
sp_id=$(az ad sp create --id $app_id --query id -o tsv 2>/dev/null)

for phase in plan apply; do
  echo "Creating federated credential for $phase phase..."
  subject="organization:$organization:project:$project:workspace:$workspace:run_phase:$phase"

  az ad app federated-credential create \
    --id $app_id \
    --parameters "{
      \"name\": \"tfc-$phase-federated-credential\",
      \"description\": \"This is a dynamic credential used by Terraform Cloud as part of the $phase phase.\",
      \"issuer\": \"https://app.terraform.io\",
      \"subject\": \"$subject\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }" &>/dev/null
done

if [ ! -z "$role" ] && [ ! -z "$subscription_id" ]; then
  echo "Creating role assignment..."
  az role assignment create \
    --assignee-object-id "$sp_id" \
    --assignee-principal-type ServicePrincipal \
    --role "$role" \
    --subscription "$subscription_id" \
    --scope "/subscriptions/$subscription_id" &>/dev/null || {
    echo "Error: Failed to create role assignment. Please verify:"
    echo "- Role name '$role' exists"
    echo "- Subscription '$subscription_id' is valid"
    echo "- You have sufficient permissions to create role assignments"
    echo "The Service Principal has still been created, but the role assignment failed and should be applied manually."
  }
fi

echo -e "\nAdd the following environment variables to your Terraform Cloud workspace:"
echo "- TFC_AZURE_PROVIDER_AUTH = true"
echo "- TFC_AZURE_RUN_CLIENT_ID = $app_id"
