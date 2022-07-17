#!/bin/bash

BASE_IMAGES=(
    "ubuntu:18.04"
    "ubuntu:20.04"
    "ubuntu:22.04"
)
IMAGE_TAG_BASE=ubuntu-server-bootstrap

for base_image in "${BASE_IMAGES[@]}"; do
    echo "Running tests with ${base_image}"
    docker build \
        --progress=plain \
        --build-arg BASE_IMAGE=${base_image} \
        -t "${IMAGE_TAG_BASE}-${base_image}" \
        .
done
