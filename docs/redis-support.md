# Connecting to and Debugging a Cloud.gov Redis Service

The motivation for this feature/functionality was when the Data.gov catalog redis
service became full and started to give the following error.
```bash
Redis Exception: OOM command not allowed when usedmemory > `maxmemory`
```

Unlike the database backup/restore scripts, There is currently no automated or
scripted version of these steps because they are lightweight enough that they
can be easily duplicated and are very application-specific.

## Deploy backup-manager to cloud.gov space

This is assumed to be pipeline-specific and out-of-scope for this guide.

## SSH onto backup-manager

If SSH access is not enabled:
```bash
cf allow-space-ssh <space>
cf enable-ssh backup-manager
cf rs backup-manager
```

## Configure Redis Connection details

Grab/Generate a key to initiate a connection with redis:
```bash
cf csk <redis-service> <new-key-name>
cf service-key <redis-service> <new-key-name>
```

Create a file with any name.  We will use `stunnel.conf` for this guide.
Use the host and port referenced above to substitute `<redis-server-host>`
and `<redis-server-port>` in the template below.
```py
fips = no
setuid = nobody
setgid = nogroup
pid = /app/pids/stunnel.pid
debug = 7
delay = yes
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[redis-cli]
  client = yes
  accept = 127.0.0.1:8000
  connect = <redis-server-host>:<redis-server-port>
```

Note: multiple redis connections can be defined, just copy the `[redis-cli]`
block and change the block name, port number and connect details, e.g.
```py
[redis-cli2]
  client = yes
  accept = 127.0.0.1:8002
  connect = <redis-server2-host>:<redis-server2-port>
```

## Start stunnel

Run the following command with the path+filename that you created above.
If it is in the same directory, the path is not necessary.
```bash
stunnel stunnel.conf
```

## Run the redis-cli

Run the following command to initiate a connection with the redis service:
```bash
redis-cli -h localhost -p 8000
```

For cloud.gov applications, the redis service requires a password.  Once
the cli is initiated, substitute `<redis-server-password>` with the value
from the above key:
```bash
localhost:8000> AUTH <redis-server-password>
```

From here you can now run any Redis commands such as `ping` and `info` 🙂
