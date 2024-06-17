#!/bin/bash

usage() {
    echo "Usage: $0 -s <source_config> -d <destination_config>"
    echo "  -s  Source S3 configuration file path"
    echo "  -d  Destination S3 configuration file path"
    echo "  -i  Customer identifier"
    exit 1
}

while getopts ":s:d:i:" opt; do
    case $opt in
        s) SOURCE_CONFIG=$OPTARG ;;
        d) DEST_CONFIG=$OPTARG ;;
	i) IDENTIFIER=$OPTARG ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

if [ -z "$SOURCE_CONFIG" ] || [ -z "$DEST_CONFIG" ] || [ -z "$IDENTIFIER" ]; then
    usage
fi

TMP_DIR=$(mktemp -d)

cleanup() {
    echo "Removing temporary directory"
    rm -rf "$TMP_DIR"
}

# Trap to ensure cleanup is done on exit
trap cleanup EXIT

BUCKET_PREFIX="ac5bucket/${IDENTIFIER}"

echo "Copying document templates to temporary directory..."
s3cmd -r -c "$SOURCE_CONFIG" get s3://"${BUCKET_PREFIX}/documenttemplates" "${TMP_DIR}/"
if [ $? -ne 0 ]; then
    echo "Error copying document templates from source bucket to temporary directory."
    exit 1
fi

echo "Copying document templates to destination bucket..."
s3cmd -r --delete-removed -c "$DEST_CONFIG" sync "${TMP_DIR}/documenttemplates" s3://"${BUCKET_PREFIX}/"
if [ $? -ne 0 ]; then
    echo "Error copying document templates from temporary directory to destination bucket."
    exit 1
fi

echo "Operation completed successfully."
