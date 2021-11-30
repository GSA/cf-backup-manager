
.DEFAULT: test

build:
	docker-compose build

test:
	docker-compose run --rm app test/bats/bin/bats -r -p test/*.bats

production:
	docker build . -t ghcr.io/gsa/cf-backup-manager:latest


.PHONY: test
