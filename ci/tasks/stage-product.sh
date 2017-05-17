#!/bin/bash

set -e # fail fast

TILE_VERSION=$(cat tile-version/number)

echo "=============================================================================================="
echo " Staging product ${product_name} ${TILE_VERSION} to Ops Manager ${opsmgr_url} ..."
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
   stage-product \
   --product-name ${product_name} \
   --product-version "${TILE_VERSION}"
