#!/usr/bin/env bash
mysql_config_file=mysql-client.cnf
local_dump_dir=dumps


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

function generate_post_import_script() {
  [[ "$#" -lt 3 ]] && errxit "Not enough parameter provided."
  local mysql_config_file=$1
  shift
  local db_name=$1
  shift
  local local_dump_dir=$1
  if [[ ! -d "$local_dump_dir" ]]; then
   mkdir "$local_dump_dir"
  fi
  if [[ ! -d "${local_dump_dir}/post" ]]; then
    mkdir "${local_dump_dir}/post"
  fi
  rm -f ${local_dump_dir}/post/autogen_cms_domains.sql
  mysql --defaults-extra-file=${mysql_config_file} ${db_name} -e "SELECT id, domain FROM cms_domains;" | tail -n +2 | while read pk domain; do
    echo "UPDATE    cms_domains
          SET       domain = '${domain}',
                    larissa_lib = '/srv/a5_source/httpdocs/lib/',
                    dir_publish='/dev/null'
          WHERE     id = ${pk};" >>${local_dump_dir}/post/autogen_cms_domains.sql
    echo "UPDATE      cms_domains
          INNER JOIN  cms_community
          ON          cms_domains.id = cms_community.domain_id
          SET         cms_community.name = cms_domains.domain,
                      cms_community.url = CONCAT('https://', cms_domains.domain)
          WHERE       cms_domains.domain IS NOT NULL;" >>${local_dump_dir}/post/autogen_cms_domains.sql
  done
  if [[ "$?" -ne 0 ]]; then
    errxit "generating of postimport script generated failed for autogen_cms_domains.sql"
  fi
  rm -f ${local_dump_dir}/post/autogen_application_portal.sql
  mysql --defaults-extra-file=${mysql_config_file} ${db_name} -e "SELECT id, domain FROM application_portal;" | tail -n +2 | while read pk domain; do
      echo "UPDATE    application_portal
            SET       domain = '${domain}'
            WHERE     id = ${pk};" >>${local_dump_dir}/post/autogen_application_portal.sql
         done
    if [[ "$?" -ne 0 ]]; then
      errxit "generating of postimport script generated failed for autogen_application_portal.sql"
    fi
    echok "Postimport script generated"
}

function print_usage_and_exit() {
  echo "Usage: ${0} [-h] -d"
  echo
  echo "This script is part of the sync porcess,"
  echo "it will create post import scripts from the destination system"
  echo
  echo "Available options:"
  echo
  echo "-h|--help                  print this help text and exit"
  echo "-d|--database-name         the name of the database from the destination system"
  echo "-l|--local_dump_dir        the dump directory where the saved domains will be stored"
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