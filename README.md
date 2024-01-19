# dbSync
A simple tool for syncing db-data from production to preview

## usage
First you have to create the dump from the source database
```bash
./createDbDump.sh -d acfive_production -l dumps
```
Now move the resulting dumpfile to wherever you can reach your destination database from.

Next you have to generate the Post-Import Script from the destination database and the drop table queries for the tables you dumped.
To work properly, your dump from the source system needs to be on the server as well.
The files generateDropTablesQueries.sh, generatePostImportFiles.sh, preDatabaseSync.sh, and excludedTables.txt
need to be on the destination system in the same directory.

```bash
./preDatabaseSync.sh -d acfive_preview -l dumps
```
This will execute the files generateDropTablesQueries.sh and generatePostImportFiles.sh

generateDropTablesQueries will go over all tables of the destination database and generate "DROP TABLE"-queries if they are not in excludedTables.txt,
then append these to the top of your dump. This is to avoid potential errors with migration scripts executed after the dump has been applied.

generatePostImportFiles will save the domainnames of your community, application, and OAS-domains to fix them after the dump has been applied.

The resulting structure will look something like this:
/tmp/dump/dump.sql
/tmp/dump/post/autogen_application_portal.sql
/tmp/dump/post/autogen_cms_domains.sql

Then you have to copy the dump files to your destination database import the files
<ol start="1">
  <li>import the main-dump: dumps/dump.sql</li>
  <li>import post import scripts from directory dumps/post/</li>
</ol>
