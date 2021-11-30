# cf-backup-manager

Cloud Foundry application to automate backup and restore of application back end data services.

## Publishing the image

The Cloud Foundry application uses a docker image published to this repository.
New images are published on any push to `main` via GitHub Actions. Make sure
these secrets are configured.

Secret | Description
------ | -----------
GITHUB_TOKEN | A GH personal access token with scope `write:packages`. |

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.


## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
