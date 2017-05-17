#!/bin/bash

set -e # fail fast

next_tile_version=$(cat tile-version/number)

echo "=============================================================================================="
echo " Reversioning product ${product_name} to version ${next_tile_version} ..."
echo "=============================================================================================="

tile_path=$(pwd)/$(ls generated-tile/${product_name}*.pivotal)
zip_tile_path=$(pwd)/generated-tile/${product_name}.zip
next_tile_path=$(pwd)/reversioned-product/${product_name}-${next_tile_version}.pivotal

mv ${tile_path} ${zip_tile_path}
unzip -u ${zip_tile_path} -d unpack
TILE_VERSION=$(cat unpack/metadata/${product_name}.yml | spruce json | jq -r .product_version)
echo "* Previous version ${TILE_VERSION}; re-versioning to ${next_tile_version}"

echo "* Updating metadata/${product_name}.yml"
sed -i -e "s/^product_version:.*$/product_version: \"${next_tile_version}\"/" unpack/metadata/${product_name}.yml

echo "* Generated manifest:"
cat unpack/metadata/${product_name}.yml

cd unpack
zip -r -f ${zip_tile_path} *
mv ${zip_tile_path} ${next_tile_path}
