#!/bin/bash

cp director_network_and_az-template.yml director_network_and_az.yml
jq --arg DIRECTOR_NETWORK $(jq -r '.variables.subnet1Name' azure-deploy.json) '.network_and_az.network.name = $DIRECTOR_NETWORK' director_network_and_az.yml > director_network_and_az.yml.tmp && mv director_network_and_az.yml.tmp director_network_and_az.yml

jq '' director_network_and_az.yml