# Test helpers for psql

psql_cmd="PGPASSWORD=psql psql -h postgres -U postgres postgres"

function psql_initdb () {
  eval "$psql_cmd -c 'CREATE TABLE users (user_id serial PRIMARY KEY, username VARCHAR ( 50 ) UNIQUE NOT NULL, age INT NOT NULL);'"
  eval "$psql_cmd -c '
		CREATE TABLE bank (
		name VARCHAR ( 50 ) PRIMARY KEY NOT NULL,
		checking INT NOT NULL
	);'"
  eval "$psql_cmd -c '
		CREATE TABLE address (
		name VARCHAR ( 50 ) PRIMARY KEY NOT NULL,
    state VARCHAR ( 10 ) NOT NULL,
		CONSTRAINT fk_users
    FOREIGN KEY(name) 
		REFERENCES users(username)
	);'"
  eval "$psql_cmd -c \"INSERT INTO users VALUES (1, 'nick', 25);\""
	eval "$psql_cmd -c \"INSERT INTO users VALUES (2, 'fuhu', 52);\""

	eval "$psql_cmd -c \"INSERT INTO bank VALUES ('nick', 100);\""
	eval "$psql_cmd -c \"INSERT INTO bank VALUES ('fuhu', 10000);\""

	eval "$psql_cmd -c \"INSERT INTO address VALUES ('nick', 'NY');\""
	eval "$psql_cmd -c \"INSERT INTO address VALUES ('fuhu', 'VA');\""

}

function psql_cleandb () {
  eval "$psql_cmd -c \"DROP TABLE bank;\""
  eval "$psql_cmd -c \"DROP TABLE address;\""
  eval "$psql_cmd -c \"DROP TABLE users;\""
}

function psql_datacheck_full () {
  eval "$psql_cmd -c 'select * from users;'" | grep "2 row"
  eval "$psql_cmd -c 'select * from bank;'" | grep "2 row"
  eval "$psql_cmd -c 'select * from address;'" | grep "2 row"
}

function psql_datacheck_skip_bank () {
  eval "$psql_cmd -c 'select * from users;'" | grep "2 row"
  eval "$psql_cmd -c 'select * from address;'" | grep "2 row"
}
