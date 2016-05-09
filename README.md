# postgresql

![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

**AtlasIT-AM/eyp-postgresql**: [![Build Status](https://travis-ci.org/AtlasIT-AM/eyp-postgresql.png?branch=master)](https://travis-ci.org/AtlasIT-AM/eyp-postgresql)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What postgresql affects](#what-postgresql-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with postgresql](#beginning-with-postgresql)
4. [Usage](#usage)
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

Installs and configures PostgreSQL on CentOS 6

## Setup

### What postgresql affects

* Installs PostgreSQL:
* configures:
  * postgres.conf
  * pg_hba
  * pg_stat_statements
* it can manage the following DB objects:
  * roles
  * schemas
* if eyp-sysctl is present:
  * overcommit_memory = 2 - total virtual address space on the system is limited to *(SWAP + RAM ·( /proc/sys/vm/overcommit_ratio /100))*
  * shmmax: maximum size of shared memory segment (default: ceiling(sprintf('%f', $::memorysize_mb)·786432))
  * shmall: total amount of shared memory available (default: ceiling(ceiling(sprintf('%f',$::memorysize_mb)·786432)/$::eyp_postgresql_pagesize))

### Setup Requirements

This module requires pluginsync enabled and **optionally** *eyp/sysctl* module
installed. Mountpoints **must** be already in place (datadir, archive_dir...)

### Beginning with postgresql

Currently, it only supports PostgreSQL 9.2 (check TODO list)

## Usage

streaming replication setup:

```puppet
node 'pgm'
{
	#.29

	class { 'sysctl': }

	class { 'postgresql':
		wal_level => 'hot_standby',
		max_wal_senders => '3',
		checkpoint_segments => '8',
		wal_keep_segments => '8',
	}

	postgresql::hba_rule { 'test':
		user => 'replicator',
		database => 'replication',
		address => '192.168.56.0/24',
	}

	postgresql::role { 'replicator':
		replication => true,
		password => 'replicatorpassword',
	}

	postgresql::schema { 'jordi':
		owner => 'replicator',
	}

}

node 'pgs'
{
	#.30

	class { 'sysctl': }

	class { 'postgresql':
		wal_level => 'hot_standby',
		max_wal_senders => '3',
		checkpoint_segments => '8',
		wal_keep_segments => '8' ,
		hot_standby => true,
		initdb => false,
	}

	class { 'postgresql::streaming_replication':
		masterhost     => '192.168.56.29',
		masterusername => 'replicator',
		masterpassword => 'replicatorpassword',
	}
}
```

backup configurtion:

```puppet
postgresql::pgdumpbackup { "backup logic":
  destination => '/backup',
  mailto => 'backup_notifications@systemadmin.es',
  idhost => 'postgresmaster01',
}
```

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
* **overcommit_memory**: modes available:
  * undef: do not change it
  * 0: heuristic overcommit (this is the default)
  * 1: always overcommit, never check
  * 2: always check, never overcommit(default: 2)',
* **shmmax**: maximum size of shared memory segment (default: ceiling(sprintf('%f', $::memorysize_mb)·786432)) you can set it to undef to disable
* **shmall**: total amount of shared memory available (default: ceiling(ceiling(sprintf('%f',$::memorysize_mb)·786432)/$::eyp_postgresql_pagesize)) you can set it to undef to disable
* for directly mapped variables (lc_messages, listen, port...) check postgres documentation, most common options are already implemented

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

## Limitations

CentOS 6 only

## Development

We are pushing to have acceptance testing in place, so any new feature should
have some tests to check both presence and absence of any feature

### TODO

* Add more postgres versions
* tablespaces management

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
