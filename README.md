# cf-backup-manager

Cloud Foundry application to automate backup and restore of application back end data services.

## Usage

### Supported services

- mysql


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
