#!/bin/bash

set -e # fail fast

stemcell_path=$(ls pivnet-stemcell/*vsphere*)

echo "=============================================================================================="
echo " Uploading stemcell ${stemcell_path} to Ops Manager ${opsmgr_url} ..."
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
   upload-stemcell \
   --stemcell "${stemcell_path}"
