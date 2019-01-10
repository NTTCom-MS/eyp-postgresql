# postgresql

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What postgresql affects](#what-postgresql-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with postgresql](#beginning-with-postgresql)
4. [Usage](#usage)
    * [pgsnapshot usage](#pgsnapshot)
5. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)
    * [TODO](#todo)
    * [Contributing](#contributing)

## Overview

manages postgresql:
* standalone
* streaming replication

## Module Description

Installs and configures PostgreSQL on CentOS 6 and 7

## Setup

### What postgresql affects

* Installs PostgreSQL:
* configures:
  * postgres.conf
  * pg_hba
  * pg_stat_statements
  * backup script using pg_dump
* it can manage the following DB objects:
  * roles
  * schemas
* if eyp-sysctl is present:
  * overcommit_memory = 2 - total virtual address space on the system is limited to *(SWAP + RAM ·( /proc/sys/vm/overcommit_ratio /100))*
  * shmmax: maximum size of shared memory segment (default: ceiling(sprintf('%f', $::memorysize_mb)·786432))
  * shmall: total amount of shared memory available (default: ceiling(ceiling(sprintf('%f',$::memorysize_mb)·786432)/$::eyp_postgresql_pagesize))

### Setup Requirements

* This module requires pluginsync enabled and **optionally** *eyp/sysctl* module installed to be able to manage **kernel.shmmax**, **kernel.shmall** and **vm.overcommit_memory**
* Mountpoints **must** be already in place (datadir, archive_dir...) and datadir **must be empty**

### Beginning with postgresql

Currently, it only supports PostgreSQL 9.2 and 9.6

## Usage

### streaming replication setup

```puppet
# 192.168.56.29
node 'pgm'
{
	class { 'sysctl': }

	class { 'postgresql':
		wal_level           => 'hot_standby',
		max_wal_senders     => '3',
		checkpoint_segments => '8',
		wal_keep_segments   => '8',
	}

	postgresql::hba_rule { 'test':
		user     => 'replicator',
		database => 'replication',
		address  => '192.168.56.0/24',
	}

	postgresql::role { 'replicator':
		replication => true,
		password    => 'replicatorpassword',
	}

	postgresql::schema { 'jordi':
		owner => 'replicator',
	}

}

# 192.168.56.30
node 'pgs'
{
	class { 'sysctl': }

	class { 'postgresql':
		wal_level           => 'hot_standby',
		max_wal_senders     => '3',
		checkpoint_segments => '8',
		wal_keep_segments   => '8' ,
		hot_standby         => true,
		initdb              => false,
	}

	class { 'postgresql::streaming_replication':
		masterhost     => '192.168.56.29',
		masterusername => 'replicator',
		masterpassword => 'replicatorpassword',
	}
}
```

### backup configurtion

```puppet
postgresql::pgdumpbackup { "backup logic":
  destination => '/backup',
  mailto      => 'backup_notifications@systemadmin.es',
  idhost      => 'postgresmaster01',
}
```

### postgresmaster using hiera

```hiera
---
classes:
  - postgresql
  - postgresql::pgstatsstatements
postgresql::port: 60901
postgresql::wal_level: hot_standby
postgresql::max_wal_senders: 3
postgresql::checkpoint_segments: 16
postgresql::wal_keep_segments: 8
postgresql::archive_mode: true
postgresql::max_connections: 200
postgresql::archive_mode: true
postgresql::archive_command_custom: 'rsync --exclude lost+found -a %p barman@192.168.52.21:/var/lib/barman/pgm/incoming/%f'
postgresql::shared_preload_libraries:
  - pg_stat_statements
postgresroles:
  extension:
    password: '1234'
    port: 60901
  extension_ro:
    password: '1234'
    port: 60901
  extension_rw:
    password: '1234'
    port: 60901
  replicator:
    port: 60901
    password: '1234'
    replication: true
postgresschemas:
  extension:
    owner: extension
    port: 60901
```

### postgres slave using hiera

```hiera
---
classes:
  - postgresql
  - postgresql::pgstatsstatements
  - postgresql::streaming_replication
postgresql::port: 60901
postgresql::wal_level: hot_standby
postgresql::max_wal_senders: 3
postgresql::checkpoint_segments: 16
postgresql::wal_keep_segments: 8
postgresql::archive_mode: true
postgresql::max_connections: 200
postgresql::initdb: false
postgresql::hot_standby: true
postgresql::shared_preload_libraries:
  - pg_stat_statements
postgresql::streaming_replication::masterhost: 192.168.52.20
postgresql::streaming_replication::masterport: 60901
postgresql::streaming_replication::masterusername: replicator
postgresql::streaming_replication::masterpassword: af35dbf3394b2b961fea37db2b2bfb0c
```

### hba rules using hiera

```hiera
---
hbarules:
  barman:
    user: postgres
    database: all
    address: '192.168.52.21/32'
    auth_method: trust
  replicator:
    user: replicator
    database: replication
    address: '192.168.52.0/24'
  nagios:
    user: nagios
    database: nagios
    address: '1.2.3.4/32'
  nagiospre:
    user: nagios
    database: nagios
    address: '1.2.3.4/32'
  extension:
    user: extension
    database: extension
    address: '192.168.52.0/24'
  extensionRO:
    user: extension_ro
    database: extension
    address: '192.168.52.0/24'
  extensionRW:
    user: extension_rw
    database: extension
    address: '192.168.52.0/24'
```

### change default schema


```puppet
class { 'postgresql':
  wal_level           => 'hot_standby',
  max_wal_senders     => '3',
  checkpoint_segments => '8',
  wal_keep_segments   => '8',
  version             => '9.6',
  search_path         => [ 'demoschema' ],
}
```

### pgsnapshot

This section describes pgsnapshot usage as a reference without actually install it via puppet (not recommended) using an empty config file, passing settings via cli options. Please note this is not the intended usage

```
touch demo.cfg
```

In the real world a sample config file would look like this:

```
[pgsnapshot]
snapsize=30G
to=backup.reports@systemadmin.es
host-id=cpe0014535
keeplvmsnaps=0
keepAWSsnapdays=7
aws=true
```

#### config file options

All options need to be in the **[pgsnapshot]** section

* **pgusername**: Postgre's username (default: postgres)
* **to**: Send a backup report to this address (default: do not send any report)
* **host-id**: Force a specific host id (default: server's FQDN)
* **lvmdisk**: Use a specific LVM disk (default: connect to postgres to get the actual datadir)
* **snapsize**: Snapshot size - recommended to be large if you plan to keep snapshots and small if you plan to use AWS snapshots (default: 5G)
* **keeplvmsnaps**: How many LVM snapshots to keep (default: 2)
* **snapshotbasename**: LVM snapshot basename (default: snap)
* **logdir**: Where to keep log files for each action (default: /var/log/pgsnapshot)
* **aws**: Use AWS snapshots (default: false)
* **keepAWSsnapdays**: Delete AWS snapshots older than N days (default: 7)
* **force-ami**: Force a specific AMI for the restored instance (default: use the same AMI as the running instance)

These options and the cronjob for pgsnapshot will be configured using **postgresql::backup::pgsnapshot**

#### backup - AWS snapshot

Make a AWS snapshot backups and delete AWS snapshots older that 10 days

```
localpuppetmaster.sh -d /tmp/postgres -r https://github.com/NTTCom-mS/eyp-postgresql; python /tmp/postgres/modules/postgresql/files/pgsnapshot/pgsnapshot.py -c demo.cfg -a -k 10
```

#### backup - LVM snapshot

Make a LVM snapshot backups keeping last 10 LVM snapshots

```
localpuppetmaster.sh -d /tmp/postgres -r https://github.com/NTTCom-mS/eyp-postgresql; python /tmp/postgres/modules/postgresql/files/pgsnapshot/pgsnapshot.py -c demo.cfg -K 10
```

#### list backups - AWS snapshots

```
localpuppetmaster.sh -d /tmp/postgres -r https://github.com/NTTCom-mS/eyp-postgresql; python /tmp/postgres/modules/postgresql/files/pgsnapshot/pgsnapshot.py -c demo.cfg -a -L
```

Sample output:

```
* snap.20181207000001
* snap.20181208000001
* snap.20181209000001
* snap.20181210000001
* snap.20181211000001
* snap.20181212000004
* snap.20181213000001
```

#### list backups - LVM snapshots

```
localpuppetmaster.sh -d /tmp/postgres -r https://github.com/NTTCom-mS/eyp-postgresql; python /tmp/postgres/modules/postgresql/files/pgsnapshot/pgsnapshot.py -c demo.cfg -L
```

Sample output:

```
* snap.20181207000001
* snap.20181208000001
```

#### restore - AWS snapshot

restore AWS snapshot named **snap.20181212122000**

```
localpuppetmaster.sh -d /tmp/postgres -r https://github.com/NTTCom-mS/eyp-postgresql; python /tmp/postgres/modules/postgresql/files/pgsnapshot/pgsnapshot.py -c demo.cfg -a -r snap.20181212122000

```

As output you'll get the instance id and the public DNS name, for example:

```
i-029aca55f79548fc5: ec2-63-33-65-78.eu-west-1.compute.amazonaws.com
```

The restored instance will have the same exact HBA rules a original instance

## Reference

### classes

#### postgresql

It uses the following (private) classes to install, configure and manage PostgreSQL:

* **postgresql::install**: Installation and initdb
* **postgresql::config**: Modifies configuration files
* **postgresql::service**: Manages postgres service

Options:
* **version**: version to install (default: 9.2)
* **datadir**: datadir to use (default: /var/lib/pgsql/9.2/data)
* **initdb**: boolean, true to create datadir's directies. In a standby server with streaming replication you want to set it to false (default: true)
* **manage_service**: boolean, true to manage PostgreSQL's service (default: true)
* **archive_command_custom**: custom archive command
* **archive_dir**: archive dir, if archive_command_custom is undef, it will be: *test ! -f ${archive_dir}/%f && cp %p ${archive_dir}/%f*
* **archive_dir_user**: archive dir user (default: undef)
* **archive_dir_group**: archive dir group (default: undef)
* **archive_dir_mode**: archive dir mode (default: undef)
* **archive_dir_chmod**: chmod to this mask if using archive_dir (default: undef)
* **overcommit_memory**: modes available:
  * undef: do not change it
  * 0: heuristic overcommit (this is the default)
  * 1: always overcommit, never check
  * 2: always check, never overcommit(default: 2)',
* **shmmax**: maximum size of shared memory segment (default: ceiling(sprintf('%f', $::memorysize_mb)·786432)) you can set it to undef to disable
* **shmall**: total amount of shared memory available (default: ceiling(ceiling(sprintf('%f',$::memorysize_mb)·786432)/$::eyp_postgresql_pagesize)) you can set it to undef to disable
* for directly mapped variables (lc_messages, listen, port...) check postgres documentation:
  * port (default: 5432)
  * listen (default: \*)
  * max_connections (default: 100)
  * wal_level (default: hot_standby)
  * max_wal_senders (default: 0)
  * checkpoint_segments (default: 16)
  * wal_keep_segments (default: 0)
  * hot_standby
  * pidfile
  * log_directory
  * log_filename
  * track_activities
  * track_counts
  * autovacuum:
    - cleanup is triggered whenever the number of dead tuples (which you can see as pg_stat_all_tables.n_dead_tup) exceeds **threshold + pg_class.reltuples * scale_facto**
  * autovacuum_vacuum_scale_factor (default: 0.0)
  * autovacuum_vacuum_threshold (default: 5000)
  * autovacuum_analyze_scale_factor (default: 0.0)
  * autovacuum_analyze_threshold (default: 5000)
  * autovacuum_freeze_max_age (default: undef)
  * timezone
  * log_timezone
  * superuser_reserved_connections
  * archive_mode
  * archive_timeout
  * archived_wals_retention
  * archived_wals_hour
  * archived_wals_minute
  * archived_wals_month
  * archived_wals_monthday
  * archived_wals_weekday
  * maintenance_work_mem
  * wal_buffers
  * work_mem
  * shared_buffers (autocalculated to 1/4 main RAM)
  * lc_messages (default: C)
  * lc_monetary (default: en_US.UTF-8)
  * lc_numeric (default: en_US.UTF-8)
  * lc_time (default: en_US.UTF-8)
  * default_text_search_config (default: pg_catalog.english)
  * shared_preload_libraries (default: undef)

usage example:

```puppet
class { 'postgresql': }
```

#### postgresql::streaming_replication

* **masterhost**: required, postgres master
* **masterusername**: required, replication username
* **masterpassword**: required, replication password
* **masterport** (default: port_default)
* **datadir** (default: datadir_default)
* **restore_command**: (default: undef)

It requires to have **pg_basebackup** and the defined username already created on
the master DB

usage example:

```puppet
class { 'postgresql::streaming_replication':
  masterhost     => '192.168.56.29',
  masterusername => 'replicator',
  masterpassword => 'replicatorpassword',
}
```

#### postgresql::pgstatsstatements

Enable pg_stats_statements:

* **track_utility**: (default: true)
* **track**: (default: all)
* **max**: (default: 10000)

usage example:

```puppet
class { 'postgresql::pgstatsstatements': }
```

### defines

#### postgresql::role

manages roles (alias users):

* **rolename**: role to define (default: resource's name)
* **password**: password for this role (if it's not a group)
* **login**: boolean, enable or disable login grant (default: true)
* **superuser** boolean, enable or disable superuser grant (default: false)
* **replication** boolean, enable or disable replication grant (default: false)

usage example:

```puppet
postgresql::role { 'jordi':
  superuser => true,
  password => 'fuckyeah',
}
```

#### postgresql::schema

Manages schemas:

* **schemaname**: schema to create (default: resource's name)
* **owner**: required, schema's owner

usage example:

```puppet
postgresql::schema { 'jordidb':
  owner => 'jordi',
}
```

#### postgresql::hba_rule

creates rules to pg_hba:

* **user**: "all", a user name, a group name prefixed with "+", or a
comma-separated list thereof.  In both the DATABASE and USER fields
you can also write a file name prefixed with "@" to include names
from a separate file.

* **database**: "all", "sameuser", "samerole", "replication", a database name,
or a comma-separated list thereof. The "all" keyword does not match "replication".
Access to replication must be enabled in a separate record (see example below).
* **address**: specifies the set of hosts the record matches.  It can be a
host name, or it is made up of an IP address and a CIDR mask that is
an integer (between 0 and 32 (IPv4) or 128 (IPv6) inclusive) that
specifies the number of significant bits in the mask.  A host name
that starts with a dot (.) matches a suffix of the actual host name.
Alternatively, you can write an IP address and netmask in separate
columns to specify the set of hosts.  Instead of a CIDR-address, you
can write "samehost" to match any of the server's own IP addresses,
or "samenet" to match any address in any subnet that the server is
directly connected to.
* **type**: it can be set to:
  * **local** is a Unix-domain socket
  * **host** is either a plain or SSL-encrypted TCP/IP socket,
  * **hostssl** is an SSL-encrypted TCP/IP socket
  * **hostnossl** is a plain TCP/IP socket. (default: host)
* **auth_method**: can be:
  * **trust**
  * **reject**
  * **md5** (default)
  * **password** (clear text passwords!)
  * **gss**
  * **sspi**
  * **krb5**
  * **ident**
  * **peer**
  * **pam**
  * **ldap**
  * **radius**
  * **cert**
* **auth_option**: set of options for the authentication in the format
NAME=VALUE.  The available options depend on the different
authentication methods(default: undef)
* **description**: description to identify each rule, see example below (default: resource's name)
* **order**: if any (default: 01)

usage example:

```puppet
postgresql::hba_rule { 'test':
  user => 'replicator',
  database => 'replication',
  address => '192.168.56.0/24',
}
```
It will create the following pg_hba rule:

```
# rule: test
host	replication	replicator	192.168.56.30/32			md5
```

#### postgresql::pgdumpbackup

* **destination**: path to store backups
* **pgroot**: Postgres installation base (default: undef)
* **instance**: postgres instance (default: undef)
* **retention**: (default: 7)
* **dbs**: dbs to backup (default: ALL)
* **mailto**: notify by mail (default: undef)
* **idhost**: host ID, if this variabla is set to undef, it will use it's fqdn
* **basedir**: path to install the backup script (default: /usr/local/bin)
* **ensure**: presence or absence of this backup script (default: present)
* **username**: user to perform backups (default: postgres)
* cron settings:
  * **setcronjob**: create a cronjob (default: true)
  * **hour_cronjob**: hour (default: 2)
  * **minute_cronjob**: minute (default: 0)
  * **month_cronjob**: month (default: undef)
  * **monthday_cronjob**: monthday (default: undef)
  * **weekday_cronjob**: weekday (default: undef)

example setup:

```puppet
postgresql::pgdumpbackup { "backup logic":
  destination => '/backup',
  mailto => 'backup_notifications@systemadmin.es',
  idhost => 'postgresmaster01',
}
```

#### postgresql::backup::pgsnapshot

Backups using pgsnapshot:

* **ensure**: Whether the cronjob and the script itseld should be in the system (default: present)
* **username**: Postgre's username (default: postgres)
* **backupname**: Backup job name (default: resource's name)
* **mailto**: Send a backup report to this address (default: undef)
* **idhost**: Force a specific host id (default: undef, server's FQDN)
* **basedir**: Where to install backup script (default: /usr/local/bin)
* **confdir**: Where to store configuration file (default: /etc)
* **lvm_disk**: Use a specific LVM disk (default: undef, connect to postgres to get the actual datadir)
* **aws**: Use AWS snapshots (default: false)
* **snap_size**: Snapshot size - recommended to be large if you plan to keep snapshots and small if you plan to use AWS snapshots (default: 5G)
* **keeplvmsnaps**: How many LVM snapshots to keep (default: 2)
* **keep_aws_snaps_days**: Delete AWS snapshots older than N days (default: 7)
* **snapshot_basename**: LVM snapshot basename (default: pgsnap)
* **logdir**: Log directory (default: /var/log/pgsnapshot)
* **force_ami**: Force a specific AMI for the restored instance (default: undef, use the same AMI as the running instance)
* cron settings:
  * **setcronjob**: create a cronjob (default: true)
  * **hour_cronjob**: hour (default: 2)
  * **minute_cronjob**: minute (default: 0)
  * **month_cronjob**: month (default: undef)
  * **monthday_cronjob**: monthday (default: undef)
  * **weekday_cronjob**: weekday (default: undef)


## Limitations

Tested in CentOS 6 and 7

## Development

We are pushing to have acceptance testing in place, so any new feature should
have some tests to check both presence and absence of any feature

### TODO

* Add more postgres versions
* tablespaces management
* Rewrite class relationships
* Improve default config: https://github.com/le0pard/pgtune/blob/master/webpack/selectors/configuration.js

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
