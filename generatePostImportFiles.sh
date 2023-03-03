#!/usr/bin/env bash
mysql_config_file=mysql-client.cnf
location=$( cd "$(dirname "$0")" ; pwd -P )
local_dump_dir=dumps

source ${location}/functions.sh

function print_usage_and_exit() {
  echo "Usage: ${0} [-h] -d"
  echo
  echo "This script is part of the sync porcess,"
  echo "it will create post import scripts from the destination system"
  echo
  echo "Available options:"
  echo
  echo "-h|--help                  print this help text and exit"
  echo "-d|--destination-url url   the destination url for which the update should be executed"
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


generate_post_import_script ${mysql_config_file} ${database_name} ${local_dump_dir}