#!/bin/bash

set -e # fail fast

echo "=============================================================================================="
echo " Configuring product ${product_name} at Ops Manager ${opsmgr_url} ..."
echo "=============================================================================================="

insecure=
skip_ssl=
if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  insecure="-k"
  skip_ssl="--skip-ssl-validation"
fi

# Get Elastic Runtime product ID
ert_guid=$(om --target ${opsmgr_url} \
  --skip-ssl-validation \
  --username "${opsmgr_username}" \
  --password "${opsmgr_password}" \
  curl \
  --silent \
  --path /api/v0/deployed/products | \
  jq -r '.[] | select(.type == "cf") | .guid')

# Get Elastic Runtime System Domain
ert_system_domain=$(om --target ${opsmgr_url} \
  --skip-ssl-validation \
  --username "${opsmgr_username}" \
  --password "${opsmgr_password}" \
  curl \
  --silent \
  --path /api/v0/staged/products/${ert_guid}/properties | \
  jq -r '.properties[".cloud_controller.system_domain"].value')

# Get Elastic Runtime Apps Domain
ert_apps_domain=$(om --target ${opsmgr_url} \
  --skip-ssl-validation \
  --username "${opsmgr_username}" \
  --password "${opsmgr_password}" \
  curl \
  --silent \
  --path /api/v0/staged/products/${ert_guid}/properties | \
  jq -r '.properties[".cloud_controller.apps_domain"].value')

# Generate System Domain SSL certificates
ert_system_domain_ssl_rsa_certificate=$(om --target ${opsmgr_url} \
  --skip-ssl-validation \
  --username "${opsmgr_username}" \
  --password "${opsmgr_password}" \
  curl \
  --silent \
  --request POST \
  --path /api/v0/certificates/generate \
  --data "{ \"domains\": [\"*.${ert_system_domain}\", \"*.login.${ert_system_domain}\", \"*.uaa.${ert_system_domain}\"] }")
ert_system_domain_ssl_cert=$(echo ${ert_system_domain_ssl_rsa_certificate} | jq -r '.certificate')
ert_system_domain_ssl_key=$(echo ${ert_system_domain_ssl_rsa_certificate} | jq -r '.key')

# Generate Apps Domain SSL certificates
ert_apps_domain_ssl_rsa_certificate=$(om --target ${opsmgr_url} \
  --skip-ssl-validation \
  --username "${opsmgr_username}" \
  --password "${opsmgr_password}" \
  curl \
  --silent \
  --request POST \
  --path /api/v0/certificates/generate \
  --data "{ \"domains\": [\"*.${ert_apps_domain}\"] }")
ert_apps_domain_ssl_cert=$(echo ${ert_apps_domain_ssl_rsa_certificate} | jq -r '.certificate')
ert_apps_domain_ssl_key=$(echo ${ert_apps_domain_ssl_rsa_certificate} | jq -r '.key')

# Update product networks
networks_json_file="tile/ci/product/networks.json"
perl -pi -e "s|{{opsmgr_default_az}}|${opsmgr_default_az}|g" ${networks_json_file}
perl -pi -e "s|{{opsmgr_default_network}}|${opsmgr_default_network}|g" ${networks_json_file}
product_networks=$(cat ${networks_json_file})
echo "* Networks:"
echo ${product_networks}

# Update product properties
properties_json_file="tile/ci/product/properties.json"
jq --arg ert_system_domain_ssl_cert "${ert_system_domain_ssl_cert}" \
    --arg ert_system_domain_ssl_key "${ert_system_domain_ssl_key}" \
    --arg ert_apps_domain_ssl_cert "${ert_apps_domain_ssl_cert}" \
    --arg ert_apps_domain_ssl_key "${ert_apps_domain_ssl_key}" \
    '.[".haproxy.system_ssl_rsa_certificate"].value.cert_pem=$ert_system_domain_ssl_cert |
     .[".haproxy.system_ssl_rsa_certificate"].value.private_key_pem=$ert_system_domain_ssl_key |
     .[".haproxy.apps_ssl_rsa_certificate"].value.cert_pem=$ert_apps_domain_ssl_cert |
     .[".haproxy.apps_ssl_rsa_certificate"].value.private_key_pem=$ert_apps_domain_ssl_key' \
    ${properties_json_file} > ${properties_json_file}.temp && mv ${properties_json_file}.temp ${properties_json_file}
product_properties=$(cat ${properties_json_file})
echo "* Properties:"
echo ${product_properties}

# Configure product
om --target ${opsmgr_url} \
   ${skip_ssl} \
   --username "${opsmgr_username}" \
   --password "${opsmgr_password}" \
   configure-product \
   --product-name ${product_name} \
   --product-network "${product_networks}" \
   --product-properties "${product_properties}"
