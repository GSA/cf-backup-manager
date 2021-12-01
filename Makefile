
.DEFAULT: test

BATS_ARGS:=--recursive --pretty

build:
	docker-compose build

test:
	docker-compose run --rm app test/bats/bin/bats $(BATS_ARGS) test/*.bats

production:
	docker build . -t ghcr.io/gsa/cf-backup-manager:latest


.PHONY: test
