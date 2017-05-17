#!/bin/bash

set -e # fail fast

TILE_VERSION=$(cat tile-version/number)
filename=${product_name}-${TILE_VERSION}.pivotal

echo "=============================================================================================="
echo " Promoting product ${product_name} version ${TILE_VERSION} ..."
echo "=============================================================================================="
aws s3 cp s3://${from_bucket}/${filename} s3://${to_bucket}/${filename}
