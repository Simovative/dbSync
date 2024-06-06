#!/bin/bash

echo "There is currently a minio client bug preventing this script from working."
echo "Bug Reference: https://github.com/minio/mc/issues/4893"
exit -1

usage() {
    echo "Usage: $0 -s <source_config> -d <destination_config>"
    echo "  -s  Source S3 configuration directory path"
    echo "  -d  Destination S3 configuratio directory path"
    exit 1
}

while getopts ":s:d:" opt; do
    case $opt in
        s) SOURCE_CONFIG=$OPTARG ;;
        d) DEST_CONFIG=$OPTARG ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

if [ -z "$SOURCE_CONFIG" ] || [ -z "$DEST_CONFIG" ]; then
    usage
fi

if command -v mcli &> /dev/null; then
    MC="mcli"
elif command -v mc &> /dev/null; then
    VERSION=$(mc --version 2>&1)

    if echo "$VERSION" | grep -q "MinIO Client"; then
	MC="mc"
    else
	echo "Could not find MinIO Client. Please make sure it is installed and run the script again."
    fi
fi

TMP_DIR=$(mktemp -d)
mkdir -p "${TMP_DIR}/documenttemplates"
mkdir -p "${TMP_DIR}/document_files"

cleanup() {
    echo "Removing temporary directory"
    rm -rf "$TMP_DIR"
}

# Trap to ensure cleanup is done on exit
trap cleanup EXIT

BUCKET_PREFIX="ac5bucket/mycustomeridentifier"

echo "Copying document templates to temporary directory..."
$MC -C "$SOURCE_CONFIG" cp -r s3://"${BUCKET_PREFIX}/documenttemplates" "${TMP_DIR}/documenttemplates"
if [ $? -ne 0 ]; then
    echo "Error copying document templates from source bucket to temporary directory."
    exit 1
fi

echo "Copying document files to temporary directory..."
$MC -C "$SOURCE_CONFIG" cp -r s3://"${BUCKET_PREFIX}/document_files" "${TMP_DIR}/documentfiles"
if [ $? -ne 0 ]; then
    echo "Error copying document files from source bucket to temporary directory."
    exit 1
fi


echo "Copying document templates to destination bucket..."
$MC -C "$DEST_CONFIG" cp -r "${TMP_DIR}/documenttemplates" s3://"${BUCKET_PREFIX}/documenttemplates/"
if [ $? -ne 0 ]; then
    echo "Error copying document templates from temporary directory to destination bucket."
    exit 1
fi

echo "Copying document files to destination bucket..."
$MC -C "$DEST_CONFIG" cp -r "${TMP_DIR}/document_files" s3://"${BUCKET_PREFIX}/document_files/"
if [ $? -ne 0 ]; then
    echo "Error copying document files from temporary directory to destination bucket."
    exit 1
fi

echo "Operation completed successfully."
