# dbSync
A simple tool for syncing db-data from production to preview

## usage
First you have to create the dump from the source database
```bash
./createDbDump.sh -d acfive -l dumps
```


Then you have to copy the dump files to your destination database import the files
<ol start="1">
  <li>import the main-dump: dumps/dump.sql</li>
  <li>import post import scripts from directory dumps/post/</li>
</ol>
