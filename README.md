# MySQL-Backup-on-Google-Cloud-Storage
This a simple tutorial for backup MySQL database on Goolge Cloud Storage

## Setup Google Cloud Storage
In this tutorial, we assume you already have an account on Google Cloud Storage. If not, please, follow official [documentation](https://cloud.google.com/storage/docs/) to achieve one.

## Install the command line tool
The ``gsutil`` command line tool is used to manage, monitor and use your storage buckets on the Google Cloud Storage. If you already installed the ``gcloud`` util, you already have the ``gsutil`` installed. Otherwise, follow the instructions for your Linux distribution from [here](https://cloud.google.com/storage/docs/gsutil_install).

## Authenticate stand-alone gsutil
If you installed the ``gcloud`` probably you are already authenticated also with the ``gsutil``. If you installed ``gsutil`` as standalone, please follow the instructions at the previous link.

## Create a Google Cloud Storage bucket
With the ``gsutil`` command line tool installed and authenticated, create a regional storage bucket named ``mysql-backups-storage`` in your current project.

      gsutil mb -c regional -l europe-west1 gs://mysql-backups-storage/
      Creating gs://mysql-backups-storage/...

## Insall MySQL Server
On your Linux server, install a MySQL server instance, for example ``mariadb-server``, enable and start it

      sudo yum install -y mariadb-server
      sudo systemctl enable mariadb
      sudo systemctl start mariadb
      
The server should be listening on port TCP 3306

      sudo netstat -natp | grep -i listen
      tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      768/sshd            
      tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      799/master          
      tcp        0      0 0.0.0.0:3306            0.0.0.0:*               LISTEN      1216/mysqld         
      tcp6       0      0 :::22                   :::*                    LISTEN      768/sshd            
      tcp6       0      0 ::1:25                  :::*                    LISTEN      799/master          

## Load a test database
To test the script, we'll load a test database in our server

      sudo yum install -y git
      git clone https://github.com/datacharmer/test_db.git

      cd test_db
      mysql -u root < employees.sql
      
      mysql -u root
      Welcome to the MariaDB monitor.  Commands end with ; or \g.
      Your MariaDB connection id is 10
      Server version: 5.5.56-MariaDB MariaDB Server

      MariaDB [(none)]> show databases;
      +--------------------+
      | Database           |
      +--------------------+
      | information_schema |
      | employees          |
      | mysql              |
      | performance_schema |
      | test               |
      +--------------------+
      5 rows in set (0.00 sec)

      MariaDB [(none)]> exit
      Bye

 Run the test suite
 
      mysql -u root -t < test_employees_md5.sql
      
      +----------------------+
      | INFO                 |
      +----------------------+
      | TESTING INSTALLATION |
      +----------------------+
      ...
      +------------------+
      | computation_time |
      +------------------+
      | 00:00:08         |
      +------------------+
      +---------+--------+
      | summary | result |
      +---------+--------+
      | CRC     | OK     |
      | count   | OK     |
      +---------+--------+

## Create the backup script
We are going to create a bash script to dump the test database into a local directory and then upload the dump files to the Google Cloud Storage bucket we just created before.

On the MySQL server machine create a local directory where to store local copy of backups

      mkdir -p /backups/mysql

Create the backup script as ``backup.sh`` file 

touch ~/backup.sh
chmod u+x ~/backup.sh

and edit the contents as following
```bash
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
backup_path="/backups/mysql"
bucket_name="mysql-backups-storage"
date=$(date +"%H:%M:%S-%d-%b-%Y")
# Set default file permissions
umask 177
# Dump database into SQL file
mysqldump --user=$user --password=$password --host=$host $db_name > $backup_path/$server-$db_name-$date.sql
# Synchronize local backup directory to a Google Cloud Storage bucket
gsutil rsync -r $backup_path gs://$bucket_name
```

















      
      
      
