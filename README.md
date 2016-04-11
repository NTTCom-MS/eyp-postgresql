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
    * [Contributing](#contributing)

## Overview

manages postgresql:
* standalone
* streaming replication

## Module Description

Installs and configures PostgreSQL on CentOS 6

## Setup

### What postgresql affects

* A list of files, packages, services, or operations that the module will alter,
  impact, or execute on the system it's installed on.
* This is a great place to stick any warnings.
* Can be in list or paragraph form.

### Setup Requirements

This module requires pluginsync enabled and **optionally** *eyp/sysctl* module
installed

### Beginning with postgresql

By default, it installs PostgreSQL 9.2

## Usage

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

## Reference

### classes

#### postgresql
#### postgresql::streaming_replication

### defines

#### postgresql::role

Create a new role:

* **rolename**: role to define (default: resource's name)
* **password**: password for this role (if it's not a group)
* **login**: boolean, enable or disable login grant (default: true)
* **superuser** boolean, enable or disable superuser grant (default: false)
* **replication** boolean, enable or disable replication grant (default: false)

for example:
```puppet
postgresql::role { 'replicator':
  replication => true,
  password => 'replicatorpassword',
}
```

#### postgresql::schema
#### postgresql::hba_rule

## Limitations

CentOS 6 only

## Development

We are pushing to have acceptance testing in place, so any new feature should
have some tests to check both presence and absence of any feature

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
