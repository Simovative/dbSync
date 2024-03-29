#!/usr/bin/env bash
mysql_config_file=mysql-client-source.cnf
excluded_tables=$(<./excludedTables.txt)
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
  echo "-d|--database_name         the name of the database from the source system"
  echo "-l|--local_dump_dir        the directory in which the dump from the source database should be put"
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

function get_excluded_tables() {
    echo ${excluded_tables}
}

function create_ignore_table_list() {
	local database_name="$1"
	for table in $( get_excluded_tables ) ; do
		[ "${table}" == "" ] && continue
    echo -n " --ignore-table=${database_name}.${table} "
	done
}


echo "starting mysqldump"
ignore_table_list=$( create_ignore_table_list "${database_name}" )


columnStatistics="--column-statistics=0"
if mysqldump --version | grep MariaDB 1>/dev/null; then
  columnStatistics=""
fi

mysqldump_command="mysqldump --defaults-extra-file=${mysql_config_file} ${columnStatistics} --no-tablespaces --single-transaction --default-character-set=utf8 --skip-set-charset"

set -o errexit
set -o pipefail

if [[ ! -d "$local_dump_dir" ]]; then
  mkdir "$local_dump_dir"
fi

## one single dump-file, only usable for small databases
export LC_CTYPE=C
export LANG=C
${mysqldump_command} ${ignore_table_list} ${database_name} | sed -e 's/^\/\*\![0-9]* DEFINER=.*//' | sed "s/\`${database_name}\`\.//g" > ${local_dump_dir}/dump.sql
