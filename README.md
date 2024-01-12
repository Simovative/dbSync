# dbSync
A simple tool for syncing db-data from production to preview

## usage
First you have to create the dump from the source database
```bash
./createDbDump.sh -d acfive_production -l dumps
```
Now move the resulting dumpfile to wherever you can reach your destination database from.

Next you have to generate the Post-Import Script from the destination database.
To work properly, this script needs to be in the same directory as the directory containing the dump:
/tmp/dump/dump.sql
/tmp/generatePostImportFiles.sh
```bash
./generatePostImportFiles.sh -d acfive_preview -l dumps
```

The resulting structure will look something like this:
/tmp/dump/dump.sql
/tmp/dump/post/autogen_application_portal.sql
/tmp/dump/post/autogen_cms_domains.sql

Then you have to copy the dump files to your destination database import the files
<ol start="1">
  <li>import the main-dump: dumps/dump.sql</li>
  <li>import post import scripts from directory dumps/post/</li>
</ol>
