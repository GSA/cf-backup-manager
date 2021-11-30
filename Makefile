
.DEFAULT: test

build:
	docker-compose build

test:
	docker-compose run --rm app test/bats/bin/bats -r -p test/*.bats

publish:
	docker build . -t grch.io


.PHONY: test
