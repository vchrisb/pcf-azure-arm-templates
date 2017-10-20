#!/bin/bash

cp director_properties-template.yml director_properties.yml
jq --arg SUBSCRIPTION_ID $SUBSCRIPTION_ID '.iaas_configuration.subscription_id = $SUBSCRIPTION_ID' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml
jq --arg TENANT_ID $TENANT_ID '.iaas_configuration.tenant_id = $TENANT_ID' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml
jq --arg CLIENT_ID $CLIENT_ID '.iaas_configuration.client_id = $CLIENT_ID' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml
jq --arg RESOURCE_GROUP $RESOURCE_GROUP '.iaas_configuration.resource_group_name = $RESOURCE_GROUP' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml
jq --arg STORAGE_NAME $STORAGE_NAME '.iaas_configuration.bosh_storage_account_name = $STORAGE_NAME' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml
jq --arg DEFAULT_SECURITY_GROUP $(jq -r '.variables.defaultNSG' azure-deploy.json) '.iaas_configuration.default_security_group = $DEFAULT_SECURITY_GROUP' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml
jq --arg SSH_PUBLIC_KEY "$(cat opsman.pub)" '.iaas_configuration.ssh_public_key = $SSH_PUBLIC_KEY' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml
jq --arg SSH_PRIVATE_KEY "$(cat opsman)" '.iaas_configuration.ssh_private_key = $SSH_PRIVATE_KEY' director_properties.yml > director_properties.yml.tmp && mv director_properties.yml.tmp director_properties.yml

jq '' director_properties.yml

