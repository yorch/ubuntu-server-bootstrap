#!/bin/bash

BASE_IMAGES=(
    "ubuntu:20.04"
    "ubuntu:22.04"
    "ubuntu:24.04"
)

BASE_IMAGE=${1:-${BASE_IMAGES[0]}}
if [[ ! " ${BASE_IMAGES[@]} " =~ " ${BASE_IMAGE} " ]]; then
    echo "Invalid base image. Choose from: ${BASE_IMAGES[*]}"
    exit 1
fi

IMAGE_TAG_BASE=ubuntu-server-bootstrap

echo "Running tests with ${BASE_IMAGE}"

docker build \
    --progress=plain \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    -t "${IMAGE_TAG_BASE}-${BASE_IMAGE}" \
    .
