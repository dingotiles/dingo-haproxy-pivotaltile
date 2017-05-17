#!/bin/bash

set -e # fail fast

product_path=$(ls generated-tile/${product_name}*.pivotal)

echo "=============================================================================================="
echo " Uploading product ${product_name} to Ops Manager ${opsmgr_url} ..."
echo "=============================================================================================="

insecure=
skip_ssl=
if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  insecure="-k"
  skip_ssl="--skip-ssl-validation"
fi

om --target ${opsmgr_url} \
   ${skip_ssl} \
   --username "${opsmgr_username}" \
   --password "${opsmgr_password}" \
   upload-product \
   --product "${product_path}"
