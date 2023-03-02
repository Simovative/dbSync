#!/usr/bin/env bash
database_name='basetables'
mysql_config_file=mysql-client.cnf
excluded_tables=$(<./excludedTables.txt)


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

mysqldump_command="mysqldump --defaults-extra-file=${mysql_config_file} --column-statistics=0 --no-tablespaces --single-transaction --default-character-set=utf8 --skip-set-charset"
echo $mysqldump_command

set -o errexit
set -o pipefail


## one single dump-file, only usable for small databases
${mysqldump_command} ${ignore_table_list} ${database_name} | sed -e 's/^\/\*\![0-9]* DEFINER=.*//' | sed "s/\`${database_name}\`\.//g" > dump.sql



##  dump.sh --output dump.sql ; pure prosa: copy plz dump.sql to preview; import.sh --input dump.sql; update einspielen