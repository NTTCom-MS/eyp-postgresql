# CHANGELOG

## 0.1.46

* bugfix pidfile: wrong defalt filename

## 0.1.45

* bugfix datadir on CentOS 7

## 0.1.44

* dependency bugfix archive command

## 0.1.43

* dependency bugfix for **postgresql::pgstatsstatements**

## 0.1.42

* added ability to change owner to **postgresql::schema**

## 0.1.41

* added support for **PostgreSQL 9.6**

## 0.1.40

* **archive_dir_chmod**: changed functionality to chmod all archived files

## 0.1.39

* force datadir for **archive_command**

## 0.1.38

* bugfix **archive_dir_chmod**

## 0.1.37

* added support for CentOS 7

## 0.1.36

* changed chmod order to be done **BEFORE** copying it to archive_dir

## 0.1.35

* added **archive_dir_chmod**, change mode after archiving WALs

## 0.1.34

* added user, group and mode to **archive_dir**
* bugfix dependencies
* updated dependency for mkdir archivedir to depend on service
* deleted dependency for cronjob

## 0.1.28

* restore_command option added to **postgresql::streaming_replication** (default: undef)
