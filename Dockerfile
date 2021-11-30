FROM alpine:3.14

RUN apk update && apk add \
  aws-cli \
  bash \
  jq \
  mysql-client \
  ncurses \
  postgresql-client \
  python3

COPY bin/ /usr/local/bin/
COPY . /app/
WORKDIR /app
ENV PROJECT_DIR=/app
