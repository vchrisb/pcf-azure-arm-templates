#!/bin/bash

cp director_networks-template.yml director_networks.yml


for i in {0..3}; do
  jq --arg NETWORK $i --arg subnetName $(jq -r --arg SUB "subnet"$(($i+1))"Name" '.variables | .[$SUB]' azure-deploy.json) '.networks[$NETWORK|tonumber].name = $subnetName' director_networks.yml > director_networks.yml.tmp && mv director_networks.yml.tmp director_networks.yml
  jq --arg NETWORK $i --arg SUBNET $(jq -r --arg SUB "subnet"$(($i+1))"Name" '.variables.virtualNetworkName + "/" + (.variables | .[$SUB])' azure-deploy.json) '.networks[$NETWORK|tonumber].subnets[0].iaas_identifier = $SUBNET' director_networks.yml > director_networks.yml.tmp && mv director_networks.yml.tmp director_networks.yml
  CIDR=$(jq -r --arg SUB "subnet"$(($i+1))"Prefix" '.variables | .[$SUB]' azure-deploy.json)
  SUB=${CIDR%????}
  jq --arg NETWORK $i --arg CIDR $CIDR '.networks[$NETWORK|tonumber].subnets[0].cidr = $CIDR' director_networks.yml > director_networks.yml.tmp && mv director_networks.yml.tmp director_networks.yml
  jq --arg NETWORK $i --arg RESERVED $SUB"0-"$SUB"10" '.networks[$NETWORK|tonumber].subnets[0].reserved_ip_ranges = $RESERVED' director_networks.yml > director_networks.yml.tmp && mv director_networks.yml.tmp director_networks.yml
  jq --arg NETWORK $i --arg GATEWAY $SUB"1" '.networks[$NETWORK|tonumber].subnets[0].gateway = $GATEWAY' director_networks.yml > director_networks.yml.tmp && mv director_networks.yml.tmp director_networks.yml
  jq --arg NETWORK $i --arg DNS "168.63.129.16" '.networks[$NETWORK|tonumber].subnets[0].dns = $DNS' director_networks.yml > director_networks.yml.tmp && mv director_networks.yml.tmp director_networks.yml
done


jq '.networks[3].service_network = true' director_networks.yml > director_networks.yml.tmp && mv director_networks.yml.tmp director_networks.yml

jq '' director_networks.yml