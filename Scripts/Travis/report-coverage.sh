#!/usr/bin/env bash

set -e
set -o pipefail

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    bash <(curl -s https://codecov.io/bash)
fi

