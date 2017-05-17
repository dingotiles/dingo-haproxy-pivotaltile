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

# Update product networks
networks_json_file="tile/ci/product/networks.json"
perl -pi -e "s|{{opsmgr_default_az}}|${opsmgr_default_az}|g" ${networks_json_file}
perl -pi -e "s|{{opsmgr_default_network}}|${opsmgr_default_network}|g" ${networks_json_file}
product_networks=$(cat ${networks_json_file})
echo "* Networks:"
echo ${product_networks}

# Update product properties
properties_json_file="tile/ci/product/properties.json"
# TODO: Add properties
product_properties=$(cat ${properties_json_file})
echo "* Properties:"
echo ${product_properties}

om --target ${opsmgr_url} \
   ${skip_ssl} \
   --username "${opsmgr_username}" \
   --password "${opsmgr_password}" \
   configure-product \
   --product-name ${product_name} \
   --product-network "${product_networks}" \
   --product-properties "${product_properties}"
