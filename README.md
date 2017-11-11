# MySQL Backup on Google Cloud Storage
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

      sudo mkdir -p /etc/mysql/backup/data

Create the backup script as ``/etc/mysql/backup/backup.sh`` file 

      sudo touch /etc/mysql/backup/backup.sh
      sudo chmod u+x /etc/mysql/backup/backup.sh

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
backup_path="/etc/mysql/backup/data"
bucket_name="mysql-backups-storage"
date=$(date +"%H:%M:%S-%d-%b-%Y")
# Set default file permissions
umask 177
# Dump database into SQL file
mysqldump --user=$user --password=$password --host=$host $db_name > $backup_path/$server-$db_name-$date.sql
# Delete files older than 2 days from local machine
find $backup_path/* -mtime +2 -exec rm {} \;
# Synchronize local backup directory to a Google Cloud Storage bucket
gsutil rsync -r $backup_path gs://$bucket_name
```

Test the script for the first time

      sudo /etc/mysql/backup/backup.sh

check if the backup file has been created on the local machine

      ls -l /etc/mysql/backup/data
      -rw-------. 1 root root 168375941 Nov 11 18:12 mysql-server-employees-18:11:57-11-Nov-2017.sql

and check if the file has been uploaded to the cloud bucket

      gsutil list gs://mysql-backups-storage
      gs://mysql-backups-storage/mysql-server-employees-18:11:57-11-Nov-2017.sql

Now we want this script to be executed every hour. To make this happens, let's to use the *Cron* daemon. Using Cron you can run scripts automatically within a specified period of time.

Check if the daemon is running

      systemctl status crond.service

If not, start and enable it

      systemctl enable crond.service
      systemctl start crond.service

To configure cron jobs, as root modify the ``/etc/crontab`` file

```bash
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed
 30  *  *  *  * root       /etc/mysql/backup/backup.sh
```

and restart the Cron daemon

      systemctl restart crond.service

So, in this simple tutorial, we enabled the backup of a MySQL database dupm file and upload the file on a remote bucket on the Goolge Cloud Storage platform.
