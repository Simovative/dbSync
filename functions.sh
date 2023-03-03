#!/bin/bash
set -o nounset

function errcho() {
  (echo >&2 "[ FAIL ] $@")
}

function errxit() {
  errcho "$@"
  exit 1
}

function echok() {
  echo "[  OK  ] $@"
}

function echoinfo() {
  echo "[ INFO ] $@"
}

function generate_post_import_script() {
  [[ "$#" -lt 3 ]] && errxit "Not enough parameter provided."
  local mysql_config_file=$1
  shift
  local db_name=$1
  shift
  local local_dump_dir=$1
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
