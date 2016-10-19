# CHANGELOG

## 0.1.37

* added support for rhel-7 and  centos-7

## 0.1.36

* changed chmod order to be done **BEFORE** copying it to archive_dir

## 0.1.35

* added **archive_dir_chmod**, change mode after archiving WALs

## 0.1.29 - 0.1.34

* added user, group and mode to **archive_dir**
* bugfix dependencies
* updated dependency for mkdir archivedir to depend on service
* deleted dependency for cronjob

## 0.1.28

* restore_command option added to **postgresql::streaming_replication** (default: undef)
