# Test helpers for psql

# psql_cmd="PGPASSWORD=psql psql -h postgres -U "
function psql_cmd () {
  PGPASSWORD="$TEST_DB_PASS" psql -h "$TEST_DB_HOST" -U "$TEST_DB_USER" "$TEST_DB_NAME" "$@"
}

function psql_initdb () {
  psql_cmd -c 'CREATE TABLE users (user_id serial PRIMARY KEY, username VARCHAR ( 50 ) UNIQUE NOT NULL, age INT NOT NULL);'
  psql_cmd -c '
		CREATE TABLE bank (
		name VARCHAR ( 50 ) PRIMARY KEY NOT NULL,
		checking INT NOT NULL
	);'
  psql_cmd -c '
		CREATE TABLE address (
		name VARCHAR ( 50 ) PRIMARY KEY NOT NULL,
    state VARCHAR ( 10 ) NOT NULL,
		CONSTRAINT fk_users
    FOREIGN KEY(name) 
		REFERENCES users(username)
	);'
  psql_cmd -c "INSERT INTO users VALUES (1, 'nick', 25);"
	psql_cmd -c "INSERT INTO users VALUES (2, 'fuhu', 52);"

	psql_cmd -c "INSERT INTO bank VALUES ('nick', 100);"
	psql_cmd -c "INSERT INTO bank VALUES ('fuhu', 10000);"

	psql_cmd -c "INSERT INTO address VALUES ('nick', 'NY');"
	psql_cmd -c "INSERT INTO address VALUES ('fuhu', 'VA');"

}

function psql_cleandb () {
  psql_cmd -c "DROP TABLE bank;"
  psql_cmd -c "DROP TABLE address;"
  psql_cmd -c "DROP TABLE users;"
}

function psql_datacheck_full () {
  psql_cmd -c 'select * from users;' | grep "2 row"
  psql_cmd -c 'select * from bank;' | grep "2 row"
  psql_cmd -c 'select * from address;' | grep "2 row"
}

function psql_datacheck_skip_bank () {
  psql_cmd -c 'select * from users;' | grep "2 row"
  psql_cmd -c 'select * from address;' | grep "2 row"
  psql_cmd -c 'select * from bank;' 2>&1 | grep "ERROR:  relation \"bank\" does not exist"
}
