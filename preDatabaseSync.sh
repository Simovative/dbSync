#!/usr/bin/env bash

function print_usage_and_exit() {
  echo "Usage: ${0} [-h] -d"
  echo
  echo "This script is part of the sync process,"
  echo "it will execute the scripts generateDropTablesQueries.sh and generateStuffFromDestination.sh"
  echo
  echo "Available options:"
  echo
  echo "-h|--help                  print this help text and exit"
  echo "-d|--database-name         the name of the database from the destination system"
  echo "-l|--local_dump_dir        the directory in which the dump from the source database lies"
  echo
  exit 0
}


[[ "$#" -lt 1 ]] && print_usage_and_exit
while [[ $# -ge 1 ]]; do
  case "$1" in
  -d | --database-name)
    database_name="$2"
    shift
    ;;
  -l | --local-dump-dir)
    local_dump_dir="$2"
    shift
    ;;
  -h | --help)
    print_usage_and_exit
    ;;
  esac
  shift
done


./generateDropTablesQueries.sh ${database_name} ${local_dump_dir}

./generatePostImportFiles.sh ${database_name} ${local_dump_dir}
