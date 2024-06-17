#!/bin/bash

usage() {
    echo "Usage: $0 -s <source_config> -d <destination_config>"
    echo "  -s  Source S3 configuration file path"
    echo "  -d  Destination S3 configuration file path"
    echo "  -a  Source bucket prefix: eg. s3://a5bucket/identifier-prod"
    echo "  -b  Target bucket prefix: eg. s3://a5bucket/identifier-stage"
    exit 1
}

while getopts ":s:d:a:b:" opt; do
    case $opt in
        s) SOURCE_CONFIG=$OPTARG ;;
        d) DEST_CONFIG=$OPTARG ;;
	      a) SOURCE_BUCKET_PREFIX=$OPTARG ;;
	      b) DEST_BUCKET_PREFIX=$OPTARG ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

if [ -z "$SOURCE_CONFIG" ] || [ -z "$DEST_CONFIG" ] || [ -z "$SOURCE_BUCKET_PREFIX" ] || [ -z "$DEST_BUCKET_PREFIX" ]; then
    usage
fi

# check if source_bucket_prefix and DEST_BUCKET_PREFIX are valid s3 paths
if [[ ! "$SOURCE_BUCKET_PREFIX" =~ ^s3://.*$ ]]; then
    echo "Source bucket must be a valid S3 path."
    exit 1
fi
if [[ ! "$DEST_BUCKET_PREFIX" =~ ^s3://.*$ ]]; then
    echo "Target bucket must be a valid S3 path."
    exit 1
fi


TMP_DIR=$(mktemp -d)

cleanup() {
    echo "Removing temporary directory"
    rm -rf "$TMP_DIR"
}

# Trap to ensure cleanup is done on exit
trap cleanup EXIT

echo "Copying document templates to temporary directory..."
s3cmd -r -c "$SOURCE_CONFIG" get "${SOURCE_BUCKET_PREFIX}/documenttemplates" "${TMP_DIR}/"
if [ $? -ne 0 ]; then
    echo "Error copying document templates from source bucket to temporary directory."
    exit 1
fi

echo "Copying document templates to destination bucket..."
s3cmd -r --delete-removed -c "$DEST_CONFIG" sync "${TMP_DIR}/documenttemplates" "${DEST_BUCKET_PREFIX}/"
if [ $? -ne 0 ]; then
    echo "Error copying document templates from temporary directory to destination bucket."
    exit 1
fi

echo "Operation completed successfully."
