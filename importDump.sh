#!/usr/bin/env bash
mysql_config_file=mysql-client-target.cnf
local_dump_dir=dumps

location=$( cd "$(dirname "$0")" ; pwd -P )

function print_usage_and_exit() {
  echo "Usage: ${0} [-h] -d"
  echo
  echo "This script is part of the sync process,"
  echo "it will create a dump of the source system"
  echo
  echo "Available options:"
  echo
  echo "-h|--help                  print this help text and exit"
  echo "-d|--database_name         the name of the database from the target system"
  echo "-l|--local_dump_dir        the directory in which the dump from the source database lays"
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

mysqlimport_command="mysql --defaults-extra-file=${mysql_config_file} --default-character-set=utf8"

set -o errexit
set -o pipefail

if [[ ! -d "$local_dump_dir" ]]; then
  mkdir "$local_dump_dir"
fi

## one single dump-file, only usable for small databases
export LC_CTYPE=C
export LANG=C
echo "start importing main dump file"
#${mysqlimport_command} ${database_name} < ${local_dump_dir}/dump.sql

echo "done importing main dump file, now starting to import post import files"
set +e
count=$(ls -1 ${local_dump_dir}/post/*.sql 2>/dev/null | wc -l)
set -e
if [ "$count" != "0" ]
then
  for file in $( ls -1 ${local_dump_dir}/post/*.sql ) ; do
    echo -n "importing $file "
    ${mysqlimport_command} ${database_name} < ${file}
    if [ $? -eq 0 ] ; then
      echo " OK"
    else
      echo " FAIL"
      echo "${file}" >> failed_files
    fi
  done
else
  echo 'no post import files found'
fi
echo 'done importing post import files'

if [[ -f "failed_files" ]]; then
    echo "$(pwd)/failed_files exists. Something went wrong please check failed_files and handle appropriate, and then continue with the process"
    exit 1
fi
