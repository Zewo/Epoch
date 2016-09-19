#!/usr/bin/env bash

set -e
set -o pipefail

# echoing here seems to have linux tests return gracefully
# else they hang and are declared failed by Travis
echo 'done'
