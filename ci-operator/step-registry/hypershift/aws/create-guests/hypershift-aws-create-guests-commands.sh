#!/bin/bash

set -euo pipefail

export KUBECONFIG="${SHARED_DIR}/management_cluster_kubeconfig"
export HYPERSHIFT_BINARY="${HYPERSHIFT_BINARY:-/hypershift/bin/hypershift}"
export AWS_SHARED_CREDENTIALS_FILE="/etc/hypershift-ci-jobs-awscreds/credentials"

if [[ -f "${SHARED_DIR}/nodepool_release_images" ]]; then
    source "${SHARED_DIR}/nodepool_release_images"
fi

if [[ -f "${SHARED_DIR}/test-plan.yaml" ]]; then
    export TEST_PLAN="${SHARED_DIR}/test-plan.yaml"
fi

# Storage KMS encryption: only forward the KMS key alias when the hypershift
# binary supports the --storage-volumes-kms-key flag. This feature detection lets
# this step merge before the hypershift change and no-op against older binaries.
if [[ -n "${HYPERSHIFT_STORAGE_KMS_KEY_ALIAS:-}" ]]; then
    if "${HYPERSHIFT_BINARY}" create cluster aws --help 2>&1 | grep -q 'storage-volumes-kms-key'; then
        echo "hypershift supports --storage-volumes-kms-key; forwarding HYPERSHIFT_STORAGE_KMS_KEY_ALIAS=${HYPERSHIFT_STORAGE_KMS_KEY_ALIAS}"
        export HYPERSHIFT_STORAGE_KMS_KEY_ALIAS
    else
        echo "hypershift binary does not support --storage-volumes-kms-key; unsetting HYPERSHIFT_STORAGE_KMS_KEY_ALIAS"
        unset HYPERSHIFT_STORAGE_KMS_KEY_ALIAS
    fi
fi

/hypershift/bin/create-guests
