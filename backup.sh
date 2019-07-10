#!/bin/bash
# Copyright 2017 - Adriano Pezzuto
# https://github.com/kalise
#
# Database credentials
user="root"
password=""
host="localhost"
server=$(hostname)
db_name="employees"
# other options
backup_path="/etc/mysql/backup/data"
bucket_name="mysql-backups-storage"
date=$(date +"%H:%M:%S-%d-%b-%Y")
# Set default file permissions
umask 177
# Dump database into SQL file
mysqldump --user=$user --password=$password --host=$host $db_name | gzip -c > $backup_path/$server-$db_name-$date.sql.gz
# Delete files older than 14 days from local machine
find $backup_path/* -mtime +14 -exec rm {} \;
# Synchronize local backup directory to a Google Cloud Storage bucket
gsutil rsync -r $backup_path gs://$bucket_name
