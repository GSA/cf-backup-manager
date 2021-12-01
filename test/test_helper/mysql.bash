# Test helpers for mysql

function mysql_cmd () {
  mysql -h mysql -u app --password=mysql-password application-mysql-db
}
