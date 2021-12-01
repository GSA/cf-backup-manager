# cf-backup-manager

Cloud Foundry application to automate backup and restore of application back end data services.

## Usage

The backup-manager runs as a Cloud Foundry application with zero instances. Most backup/restore commands should be run via [Cloud Foundry task](https://docs.cloudfoundry.org/devguide/using-tasks.html).

    $ cf run-task backup-manager --wait --name dashboard-restore --command 'restore mysql dashboard-db /backup-manager-v1/development/dashboard-db/dashboard-db-20211201022504-backup.gz'

Inspect the currently running tasks.

    $ cf tasks backup-manager

Monitor the backup-manager logs during task run.

    $ cf logs backup-manager | grep APP/TASK/dashboard-restore

If you need to SSH into the container, make sure to set the path so that the
commands are available to you.

    $ PATH=/usr/local/bin:$PATH


### Supported services

- mysql


### Commands

#### list [path]

List the contents of the backup-manager-s3 bucket.

#### backup <service_type> <service_name> [backup_path]

Create a backup for the named service. You must specify the service type e.g.
mysql. If you don't provide a backup path, then one will be generated in the
form:

> /backup-manager-v1/$space/$service_name/$service_name-$datetime-backup.gz

#### restore <service_type> <service_name> <backup_path>

Restore the named backup to the specified service.

### Migrations

You can also use this application to migrate databases from outside of Cloud
Foundry.

1. Get a service key for the backup-manager-s3 service
1. Use these credentials to export and upload your backup to the
   backup-manager-s3
1. Restore the backup to your Cloud Foundry service

First, create a service key for the backup-manager-s3 service.

    $ cf create-service-key backup-manager-s3 fcs-migration
    $ cf service-key backup-manager-s3 fcs-migration

Use these credentials with the AWS CLI to backup to the backup-manager-s3
bucket. You can create a secure tmp file and set these variables:

```
# create this file with mktemp
# /tmp/tmp.abcef
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export BUCKET_NAME=
export AWS_DEFAULT_REGION=us-gov-west-1
```

Here's an example using `mysqldump` to export and upload to our backup-manager-s3 bucket.

    $ source /tmp/tmp.abcdef
    $ time mysqldump --host "$DB_HOST" --password="$DB_PASSWORD" --user "$DB_USER" --no-create-db --verbose "$DB_NAME" | gzip | aws s3 cp - s3://${BUCKET_NAME}/migrations/mysql-dashboard-migration.sql.gz

Now that your backup is in the backup-manager-s3 bucket, you can restore it to
your service.

    $ cf run-task backup-manager --wait --name mysql-migration --command 'restore mysql dashboard-db /migrations/mysql-dashboard-migration.sql.gz'

Once complete, you should have your database migrated to Cloud Foundry.


### Setup

1. Create the backup-manager-s3 service where backups will be stored
1. Share the backup-manager-s3 service with each space you want to backup
1. Push the backup-manager app to each space you want to backup
1. Bind the backup-manager-s3 service
1. Bind any target services to be backed up

First, create the S3 service in your management space.

    $ cf target -s management
    $ cf create-service s3 basic backup-manager-s3

Share the S3 service with each space.

    $ cf share-service backup-manager-s3 -s production

Push the application to each space that you want to backup. This helps to avoid
conflicts with services that might not have unique names across spaces.

    $ cf target -s production
    $ cf push backup-manager -f manifest.yml --vars-file vars.production.yml

Bind the backup-manager-s3 service to the backup-manager app in each space.

    $ cf target -s production
    $ cf bind-service backup-manager backup-manager-s3

Bind any target services you want to backup to the backup-manager app.

    $ cf target -s production
    $ cf bind-service backup-manager dashboard-db

You're ready to make some backups!


## Implementing additional services

Each service must implement this API:

- **service_get_credentials_env**: parses the service credentials from VCAP_SERVICES
  and echos them to stdout to be evaluated by the shell.
- **service_backup**: runs commands to backup the service to stdout.
- **service_restore**: runs commands to restore the service from stdin.

Function name | arguments | stdin | stdout
------------- | --------- | ----- | ------
`service_get_credentials_env` | 1: name of the service instance |  N/A | Credentials in environment variable (env=val) form. These variables are consumed by `service_backup` and `service_restore`.
`service_backup` | N/A | N/A | Pipes service backup data to stdout
`service_restore` | N/A | Restores service instance from data read from stdin | N/A


## Publishing the image

The Cloud Foundry application uses a docker image published to this repository.
New images are published on any push to `main` via GitHub Actions.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.


## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
