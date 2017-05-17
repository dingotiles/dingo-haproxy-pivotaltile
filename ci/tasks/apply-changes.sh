#!/bin/bash

set -e # fail fast

echo "=============================================================================================="
echo " Applying changes to Ops Manager ${opsmgr_url} ..."
echo "=============================================================================================="

insecure=
skip_ssl=
if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  insecure="-k"
  skip_ssl="--skip-ssl-validation"
fi

ignore_warnings=
if [[ "${opsmgr_ignore_warnings}X" != "X" ]]; then
  ignore_warnings="--ignore-warnings"
fi

om --target ${opsmgr_url} \
   ${skip_ssl} \
   --username "${opsmgr_username}" \
   --password "${opsmgr_password}" \
   apply-changes \
   ${ignore_warnings}
