#!/bin/bash

cd $(dirname $0)

source ./config

if [ ! -f files/Xilinx.lic ]; then
    echo "Xilinx.lic license file not found. Cannot continue."
    exit 1
fi

if [ ! -f files/$VIVADO_SETUP ]; then
    echo "Xilinx Vivado installation .tar.gz file not found. Cannot continue."
    exit 1
fi

trap 'kill $(jobs -p)' EXIT

# Start webserver for setup file download
python3 -m http.server --bind $DOCKERHOST_IP 8000 &

# Build the docker container
#docker build --no-cache --rm --build-arg VIVADO_VERSION=$VIVADO_VERSION --build-arg VIVADO_SETUP=$VIVADO_SETUP --build-arg DOCKERHOST_IP=$DOCKERHOST_IP -t $IMAGE_NAME .
docker build --build-arg VIVADO_VERSION=$VIVADO_VERSION --build-arg VIVADO_SETUP=$VIVADO_SETUP --build-arg DOCKERHOST_IP=$DOCKERHOST_IP -t $IMAGE_NAME .

exit $?
