## Backup an application database
Run like this example:
```
$ sh app-db-backup.sh 
App name (inventory|catalog)> catalog
```

It will create a db dump file such as `catalog-db-20230714-110218-development.gz`

## Restore a database backup
`catalog-db-restore.sh` is multi-purposed script and includes a lot of steps for specific catalog use case. Use  `app-db-restore.sh` if you just want to restore a DB backup.

First you need to create a new database, such as 
```
cf create-service aws-rds medium-gp-psql catalog-new-db -c "{\"storage\": 250, \"version\": \"12\"}"
```
Use the existing DB for correct db plan and storage size

then run this script, providing the backup file and new DB name:
```
$ sh app-db-restore.sh 
S3 Backup path> catalog-db-20230714-110218-development.gz
New Service name> catalog-new-db
```