# Overview

This repository contains scripts and a Terraform configuration to create federated credentials within Azure to use with Terraform Cloud.

# Resources Created
Each option provided will create the following resources:
- Azure Entra ID Application
- Azure Entra ID Service Principal
- Federated Identity Credentials for Terraform Cloud
- Role Assignment for the Service Principal on a given subscription (if provided)

# Creation Options

## 1. `federated-credential.tf`
This example code can be used in your Terraform code to create the necessary resources for federated credentials.

### Usage
To use this Terraform configuration, you will need to provide the following mandatory and optional variables when running `terraform apply`:

* **Mandatory Variables**
  * **organization** - The HashiCorp Terraform Cloud organisation name
  * **project** - The Terraform Cloud project name
  * **workspace** - The Terraform Cloud workspace name
  * **sp_name** - The name of the service principal that you'd like to use
* **Optional Variables**
  * **role** - The role that you'd like to assign to the service principal on the Azure subscription provided with the `subscription_id` variable. Defaults to `Contributor`
  * **subscription_id** - The Azure subscription ID that you'd like to assign the service principal to.

## 2. `New-FederatedCredential.ps1`
When using this PowerShell script, you can either provide values as flags, or just run the script and it will prompt interactively for the required parameters.

### Usage
To use this PowerShell script, follow these steps:

1. **Open PowerShell** and navigate to the directory containing the script.

2. **Run the script** with the required parameters (or provide them interactively by just running the script without any parameters).

### Examples

Examples of running the script are shown below:

```powershell
# Providing all required parameters

.\New-FederatedCredential.ps1 --Organization "my-org" --Project "my-project" --Workspace "my-workspace" --SpName "tfc-federated-credential" --Role "Contributor" --SubscriptionId "bc884483-24ef-40c5-b8d4-0c35a50ca8f8"
```

```powershell
# Providing only the mandatory parameters

.\New-FederatedCredential.ps1 --Organization "my-org" --Project "my-project" --Workspace "my-workspace" --SpName "tfc-federated-credential"
```

```powershell
# Providing mandatory parameters using the short flag syntax

.\New-FederatedCredential.ps1 -o "my-org" -p "my-project" -w "my-workspace" -s "tfc-federated-credential"
```

```powershell
# Providing all parameters interactively

.\New-FederatedCredential.ps1
```

## 3. `create-federated-credential.sh`
When using this Bash script, you can either provide values as flags, or just run the script and it will prompt interactively for the required parameters.

### Usage
To use this Bash script, follow these steps:

1. **Open a terminal** and navigate to the directory containing the script.

2. **Run the script** with the required parameters (or provide them interactively by just running the script without any parameters).

### Examples

Examples of running the script are shown below:

```bash
# Providing all required parameters

./create-federated-credential.sh --organization "my-org" --project "my-project" --workspace "my-workspace" --sp-name "tfc-federated-credential" --role "Contributor" --subscription_id "bc884483-24ef-40c5-b8d4-0c35a50ca8f8"
```

```bash
# Providing only the mandatory parameters

./create-federated-credential.sh --organization "my-org" --project "my-project" --workspace "my-workspace" --sp-name "tfc-federated-credential"
```

```bash
# Providing mandatory parameters using the short flag syntax

./create-federated-credential.sh -o "my-org" -p "my-project" -w "my-workspace" -s "tfc-federated-credential"
```

```bash
# Providing all parameters interactively

./create-federated-credential.sh
```
