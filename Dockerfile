FROM alpine:3.14

RUN apk update && apk add \
  aws-cli \
  bash \
  jq \
  mysql-client \
  ncurses \
  postgresql-client \
  python3 \
  redis \
  stunnel

# Add local scripts to global scope
COPY bin/ /usr/local/bin/

# Create non-privileged user
RUN adduser -S backup-manager -h /app

# Setup stunnel for secure redis connection
#  - Make stunnel executable by anyone
#  - Create folder for background processes
RUN chmod u+s /usr/bin/stunnel
RUN mkdir /app/pids
RUN chown -R backup-manager /app/pids

# Set user and starting env
USER backup-manager

COPY . /app/
WORKDIR /app
ENV PROJECT_DIR=/app
