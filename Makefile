
.DEFAULT: test

BATS_ARGS:=--recursive --pretty

build:
	docker-compose build

clean:
	docker-compose down -v --remove-orphans

production:
	docker build . -t ghcr.io/gsa/cf-backup-manager:latest

test:
	docker-compose run --rm app test/bats/bin/bats $(BATS_ARGS) test/*.bats


.PHONY: test
