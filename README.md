# PCF Azure Resource Manager (ARM) Templates

This repo contains ARM templates that help operators deploy Ops Manager Director for Pivotal Cloud Foundry (PCF). 

For more information, see the [Launching an Ops Manager Director Instance with an ARM Template](https://docs.pivotal.io/pivotalcf/customizing/azure-arm-template.html) topic.

## requirements

* [jq](https://stedolan.github.io/jq/)
* [azure cli](https://github.com/Azure/azure-cli)

## initial setup

Modify `CLIENT_SECRET` and `IDENTIFIER` and issue the command in sequence.
`IDENTIFIER`is used to make some of the required strings unique and shouldn't contain any special characters.

```
az cloud set --name AzureCloud
az login
az account list

export CLIENT_SECRET="<SECRET>"
export IDENTIFIER="<IDENTIFIER>"
export SUBSCRIPTION_ID=$(az account list | jq -r ".[0].id")
export TENANT_ID=$(az account list | jq -r ".[0].tenantId")
export RESOURCE_GROUP="pcf_resource_group"
export LOCATION="westeurope"
export OPS_MAN_IMAGE_URL="https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-1.11.5.vhd"
export STORAGE_NAME="opsmanstorage$IDENTIFIER"

az account set --subscription $SUBSCRIPTION_ID
az ad app create --display-name "Service Principal for BOSH" --password $CLIENT_SECRET --homepage "http://BOSHAzureCPI" --identifier-uris "http://BOSHAzureCPI$IDENTIFIER"

export APP_ID=$(az ad app show --id "http://BOSHAzureCPI$IDENTIFIER" | jq -r ".appId")

az ad sp create --id $APP_ID
az role assignment create --assignee "http://BOSHAzureCPI$IDENTIFIER" --role "Contributor" --scope "/subscriptions/$SUBSCRIPTION_ID"
az role assignment list --assignee "http://BOSHAzureCPI$IDENTIFIER"

az login --username $APP_ID --password $CLIENT_SECRET --service-principal --tenant $TENANT_ID

az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute

az group create --name $RESOURCE_GROUP --location $LOCATION
```

## OPSMAN
```
az storage account create --name $STORAGE_NAME --resource-group $RESOURCE_GROUP --sku Standard_LRS --kind Storage --location $LOCATION
export CONNECTION_STRING=$(az storage account show-connection-string --name $STORAGE_NAME --resource-group $RESOURCE_GROUP | jq -r ".connectionString")

az storage container create --name opsman-image --connection-string $CONNECTION_STRING
az storage container create --name vhds --connection-string $CONNECTION_STRING
az storage container create --name opsmanager --connection-string $CONNECTION_STRING
az storage container create --name bosh --connection-string $CONNECTION_STRING
az storage container create --name stemcell --public-access blob --connection-string $CONNECTION_STRING
az storage table create --name stemcells --connection-string $CONNECTION_STRING

ssh-keygen -t rsa -f opsman -C ubuntu

az storage blob copy start --source-uri $OPS_MAN_IMAGE_URL --connection-string $CONNECTION_STRING --destination-container opsman-image --destination-blob image.vhd 
az storage blob show --name image.vhd --container-name opsman-image --account-name $STORAGE_NAME | jq .properties.copy
```

Wait for the copy process to finish and modify `azure-deploy-parameters.json` with your specific variables.

```
az group deployment create --template-file azure-deploy.json --parameters azure-deploy-parameters.json --resource-group $RESOURCE_GROUP --name cfdeploy
```
In the output look for 
```JSON
    "outputs": {
      "loadbalancer-IP": {
        "type": "String",
        "value": "1.2.3.4"
      },
      "loadbalancer-SSH-IP": {
        "type": "String",
        "value": "1.2.3.5"
      },
      "opsMan-FQDN": {
        "type": "String",
        "value": "pcf-opsman-1234.westeurope.cloudapp.azure.com"
      }
```
You need to create DNS entries for `*.<system domain>` and `*.<apps domain>`to the `loadbalancer-IP` and `ssh.<system domain>` to `loadbalancer-SSH-IP`.
Connect to Opsman URL which you can find under `opsMan-FQDN` and continuing with deploying [Elastic Runtime on Azure](https://docs.pivotal.io/pivotalcf/customizing/azure-er-config.html)

## Objects created by template

### Networks
* `pcf-net` with `10.0.0.0/16`

#### Subnets
* `opsman` with `10.0.0.0/24`
* `ert` with `10.0.1.0/24`
* `service` with `10.0.2.0/24`
* `ondemand` with `10.0.3.0/24`

#### Security groups
* `opsman-nsg` with `http`, `https` and `SSH`
* `ert-nsg` with `any-any`
* `service-nsg` with `any-any`
* `ondemand-nsg` with `any-any`

### Load Balancer
* `pcf-lb` for the routers
* `pcf-ssh-lb` for SSH access to Diego Brains


