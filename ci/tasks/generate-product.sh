#!/bin/bash

set -e # fail fast

mkdir -p product-tile/tmp/metadata
mkdir -p workspace/metadata
mkdir -p workspace/releases
cp -r product-tile/migrations workspace/ # opsmgr v1.7+

TILE_VERSION=$(cat tile-version/number)
echo "=============================================================================================="
echo " Generating product ${product_name} ${TILE_VERSION} ..."
echo "=============================================================================================="

STEMCELL_VERSION=$(cat pivnet-stemcell/metadata.json | jq -r ".Release.Version")
IFS='.' read -ra STEMCELL_SERIES <<< "${STEMCELL_VERSION}"
echo "* Using stemcell series ${STEMCELL_SERIES}"

cat >product-tile/tmp/metadata/version.yml <<EOF
---
product_version: "${TILE_VERSION}"
provides_product_versions:
  - name: ${product_name}
    version: "${TILE_VERSION}"
stemcell_criteria:
  version: "${STEMCELL_SERIES}"
EOF

cat >product-tile/tmp/metadata/releases.yml <<YAML
---
releases:
YAML

# versions available via inputs
boshreleases=("haproxy" "prometheus")
for boshrelease in "${boshreleases[@]}"
do
  release_version=$(cat ${boshrelease}/version)
  echo "* Using bosh release ${boshrelease} ${release_version}"
  cat >>product-tile/tmp/metadata/releases.yml <<YAML
  - name: ${boshrelease}
    file: ${boshrelease}-${release_version}.tgz
    version: "${release_version}"
YAML
  if [[ -f ${boshrelease}/release.tgz ]]; then
    cp ${boshrelease}/release.tgz workspace/releases/${boshrelease}-${release_version}.tgz
  fi
  if [[ -f ${boshrelease}/${boshrelease}-${release_version}.tgz ]]; then
    cp ${boshrelease}/${boshrelease}-${release_version}.tgz workspace/releases/
  fi
done

spruce merge --prune meta \
  product-tile/templates/metadata/base.yml \
  product-tile/templates/metadata/stemcell_criteria.yml \
  product-tile/tmp/metadata/version.yml \
  product-tile/tmp/metadata/releases.yml \
  product-tile/templates/metadata/form_types.yml \
  product-tile/templates/metadata/install_time_verifiers.yml \
  product-tile/templates/metadata/property_blueprints.yml \
  product-tile/templates/metadata/job_haproxy.yml \
    > workspace/metadata/${product_name}.yml

sed -i "s/RELEASE_VERSION_MARKER/${TILE_VERSION}/" workspace/metadata/${product_name}.yml

echo "* Generated manifest:"
cat workspace/metadata/${product_name}.yml

echo "* Generating product ${product_name}-${TILE_VERSION}.pivotal ..."
cd workspace
zip -r ${product_name}-${TILE_VERSION}.pivotal migrations metadata releases
mv ${product_name}-${TILE_VERSION}.pivotal ../product
