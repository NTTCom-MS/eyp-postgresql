# CHANGELOG

## 0.5.4

* stick stdlib version to 4.2.1 due to ceiling function being unavailable later on
  
## 0.5.3

* added forced arch amd64 for Debian
* added support for **Debian 8, 9 and 10** and **Ubuntu 14.04, 16.04, 18.04 and 20.04**

## 0.5.2

* improved pgbouncer support with better control over the settings

## 0.5.1

* fix raspbian bug
* fix client dependency
* added support for **RHEL/CentOS 8**

## 0.5.0

* added ability to control whether the replica should be paused
* added support for **Raspbian 10**

## 0.4.12

* added more autovacuum settings
* added bonjour options
* added checkpoint settings
* added effective_io_concurrency setting; for SSD disks

## 0.4.11

* added options for setting default local entries on pg_hba

## 0.4.10

* Updated pg repo URL

## 0.4.9

* added **max_standby_archive_delay** and **max_standby_streaming_delay**

## 0.4.8

* added compliance check for **check_postgres_datadir**

## 0.4.7

* bugfix **check_replication_lag**

## 0.4.6

* added nagios compatible check for postgres replication

## 0.4.5

* Added version dependent flags:
  - max_worker_processes
  - max_parallel_workers
  - max_parallel_workers_per_gather

## 0.4.4

* added pgbouncer support

## 0.4.2

* fixed **systemd::dropin** dependency

## 0.4.1

* added postgis support to PostgreSQL 11

## 0.4.0

* **INCOMPATIBLE CHANGES**:
  - set default PostgreSQL version to **PostgreSQL 11**
  - version number for **postgresql::postgis** is now mandatory (there's no default)
* renamed **postgresql::streaming_replication** to **postgresql::recoveryconf**. Class **postgresql::streaming_replication** still exists just for compatibility
  - improved recoveryconf management adding more variables

## 0.3.6

* added **inherit** flag to **postgresql::role**
* added **install_contrib** flag to **postgresql**

## 0.3.5

* added **default_transaction_read_only** under puppet management

## 0.3.4

* added flag to control autorestart: When a config change requires the service to be restarted it can be done automatically if restart_if_needed is set to true (default: true)
* renamed recovery.conf ERB template
* added support for **PostgreSQL 11**

## 0.3.3

* enabled **log_lock_waits** by default
* added **deadlock_timeout** variable
* added **postgres::repo** and **postgres::client** classes to be able to install postgres client without installing postgres server

## 0.3.2

* added **log_line_prefix**
* added compress and purge **pg_log** directory cronjobs under puppet management

## 0.3.1

* Updated metadata for **eyp-systemd 0.2.0**

## 0.3.0

* Moved **pg_reload_conf()** from **postgresql::hba::reload** to **postgresql::config::reload**
* Postgres config reload on change instead of service restart
  - Postgres service will be restarted if there are changes that need to restart the service - **/usr/local/bin/check_postgres_pending_restart**
* Fixed package name for postgres 10 repo
* **INCOMPATIBLE CHANGE**:
  - enabled wal_compression by default for postgres >= 9.5

## 0.2.2

* added **effective_cache_size** variable (default: 3/4 memory size)
* changed default **maintenance_work_mem** to 64MB

## 0.2.1

* set timeout for pg_basebackup to 0

## 0.2.0

* Major rewrite of **::postgresql** class - No incompatible change introduced
* **pg_hba.conf**: reload service on changes instead of service restart
* added a variable to install extension for a specific DB by default for **postgresql::pgstatsstatements** and **postgresql::postgis**

## 0.1.68

* modified default value for **archive_mode** to true

## 0.1.67

* added dbname flag to **postgresql::extension**
* created **postgresql::pgstatsstatements::extension** and **postgresql::postgis::extension** to enable these extensions on an arbitrary DB

## 0.1.66

* changed default max_wal_senders from 0 to 5

## 0.1.65

* Added service dependency for **postgresql::pgdumpbackup**

## 0.1.64

* added postgres 10 support for RHEL 6/7 and CentOS 6/7
* postGIS basic support

## 0.1.63

* set max_replication_slots to 5 by default
* **postgresql::streaming_replication**:
  - added **primary_slot_name** and **recovery_min_apply_delay**
* added **postgresql::replication_slot**

## 0.1.62

* bugfix pgsnapshot: set same SubnetId for the restore instances

## 0.1.60

* improved pgsnapshot: added -R option to be able to list currently running restored instances

## 0.1.59

* configure vacuum analyze job: **postgresql::maintenance::analyze**

## 0.1.58

* added flag to disable postgres.conf management
* disable postgres.conf management on a restored instance via pgsnapshot

## 0.1.57

* added pgsnapshot.py as backup method
* added flag to disable pg_hba.conf management

## 0.1.56

* added log related variables:
  - log_min_duration_statement
  - log_file_mode

## 0.1.55

* added **archive_cleanup_command**

## 0.1.54

* added **search_path** variable

## 0.1.53

* minor feature cleanup

## 0.1.52

* bugfix postgresql::pgdumpbackup

## 0.1.51

* added extension management via **postgtresql::extension**

## 0.1.50

* bugfix: streaming replication ordering

## 0.1.49

* added **postgresql::db**

## 0.1.48

* added **autovacuum_freeze_max_age**

## 0.1.47

* added **log_autovacuum_min_duration**

## 0.1.46

* bugfix pidfile: wrong default filename

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
