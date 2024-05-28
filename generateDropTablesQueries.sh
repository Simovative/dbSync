#!/usr/bin/env bash
mysql_config_file=mysql-client-target.cnf
excluded_tables=$(<./excludedTables.txt)


function errcho() {
  (echo >&2 "[ FAIL ] $@")
}

function errexit() {
  errcho "$@"
  exit 1
}

function echok() {
  echo "[  OK  ] $@"
}

function get_excluded_tables() {
    echo ${excluded_tables}
}

function print_usage_and_exit() {
  echo "Usage: ${0} [-h] -d"
  echo
  echo "This script is part of the sync process,"
  echo "it will generate DROP TABLE queries for every table in the destination database"
  echo "excluding the ones listed in excludedTables.txt and put them at the beginning of the dump"
  echo
  echo "Available options:"
  echo
  echo "-h|--help                  print this help text and exit"
  echo "-d|--database-name         the name of the database from the destination system"
  echo "-l|--local_dump_dir        the directory in which the dump from the source database lies"
  echo
  exit 0
}

# drop all tables except excluded ones
function generate_delete_all_tables() {
  [[ "$#" -lt 2 ]] && errxit "Not enough parameter provided."
  local mysql_config_file=$1
  shift
  local database_name=$1
  shift
  local local_dump_dir=$1

  all_tables=$(mysql --defaults-extra-file=${mysql_config_file} -e "SHOW TABLES;" ${database_name} | tail -n +2)
  drop_queries="SET FOREIGN_KEY_CHECKS=0; "
  excluded_tables=$(get_excluded_tables)

  for table in $all_tables; do
    if [[ ! " $excluded_tables " =~ ${table} ]]; then
        drop_queries+="DROP TABLE IF EXISTS \`$table\`; "
    fi
  done
  drop_queries+="SET FOREIGN_KEY_CHECKS=1;"
  sed -i "1s/^/$drop_queries\n/" "${local_dump_dir}/dump.sql"
}

if [[ -n "$excluded_tables" || "$excluded_tables" == "" ]]; then
    errexit "No excluded tables provided, exiting"
fi

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

generate_delete_all_tables ${mysql_config_file} ${database_name} ${local_dump_dir}
