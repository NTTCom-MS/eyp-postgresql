class postgresql::params {

  $version_default='11'

  $port_default='5432'
  $log_directory_default='pg_log'
  $log_filename_default='postgresql-%Y%m%d.log'
  $timezone_default='Europe/Andorra'

  $pgbouncer_service_name = 'pgbouncer'
  $pgbouncer_package_name = 'pgbouncer'

  $servicename = {
                    '9.2' => 'postgresql-9.2',
                    '9.6' => 'postgresql-9.6',
                    '10' => 'postgresql-10',
                    '11' => 'postgresql-11',
                    '12' => 'postgresql-12',
                  }

  $pidfile = {
                    '9.2' => '/var/lock/subsys/postgresql-9.2',
                    '9.6' => undef,
                    '10' => undef,
                    '11' => undef,
                    '12' => undef,
                  }
  $initdb = {
              '9.2' => '/usr/pgsql-9.2/bin/initdb',
              '9.6' => '/usr/pgsql-9.6/bin/initdb',
              '10' => '/usr/pgsql-10/bin/initdb',
              '11' => '/usr/pgsql-11/bin/initdb',
              '12' => '/usr/pgsql-12/bin/initdb',
            }

  $postgis = {
              '23_10' => 'postgis23_10',
              '24_10' => 'postgis24_10',
              '25_10' => 'postgis25_10',
              '23_11' => 'postgis23_11',
              '24_11' => 'postgis24_11',
              '25_11' => 'postgis25_11',
            }

  $datadir_default = {
                        '9.2' => '/var/lib/pgsql/9.2/data',
                        '9.6' => '/var/lib/pgsql/9.6/data',
                        '10' => '/var/lib/pgsql/10/data',
                        '11' => '/var/lib/pgsql/11/data',
                        '12' => '/var/lib/pgsql/12/data',
                    }

  $packagename= {
                  '9.2' => [ 'postgresql92-server' ],
                  '9.6' => [ 'postgresql96-server' ],
                  '10'  => [ 'postgresql10-server' ],
                  '11'  => [ 'postgresql11-server' ],
                  '12'  => [ 'postgresql12-server' ],
                }

  $packagename_client = {
                          '9.2' => [ 'postgresql92' ],
                          '9.6' => [ 'postgresql96' ],
                          '10'  => [ 'postgresql10' ],
                          '11'  => [ 'postgresql11' ],
                          '12'  => [ 'postgresql12' ],
                        }

  $contrib = {
              '9.2' => 'postgresql92-contrib',
              '9.6' => 'postgresql96-contrib',
              '10' => 'postgresql10-contrib',
              '11' => 'postgresql11-contrib',
              '12' => 'postgresql12-contrib',
            }

  case $::osfamily
  {
    'redhat':
    {
      $repoprovider = 'rpm'
      $sysconfig=true

      $postgresuser='postgres'
      $postgresgroup='postgres'
      $postgreshome='/var/lib/pgsql'

      $reposource =  {
                      '9.6' => 'https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm',
                      '10' => 'https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm',
                      '11' => 'https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm',
                      '12' => 'https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm',
                      }
      $reponame = {
                    '9.6' => 'pgdg-redhat-repo',
                    '10' => 'pgdg-redhat-repo',
                    '11' => 'pgdg-redhat-repo',
                    '12' => 'pgdg-redhat-repo',
                  }

      case $::operatingsystemrelease
      {
        /^6.*$/:
        {
          $systemd=false
        }
        /^[78].*$/:
        {
          $systemd=true
        }
        default: { fail("Unsupported version! - ${::operatingsystemrelease}")  }
      }
    }
    'Debian':
    {
      case $::architecture
      {
        'armv7l':
        {
          #raspberry
          $repoprovider = 'raspbian10'
          $sysconfig=false

          $postgresuser='postgres'
          $postgresgroup='postgres'
          $postgreshome='/var/lib/pgsql'
          case $::operatingsystem
          {
            'Debian':
            {
              case $::operatingsystemrelease
              {
                /^10.*$/:
                {
                  $systemd=true
                }
                default: { fail("Unsupported Debian version! - ${::operatingsystemrelease}")  }
              }
            }
            default: { fail('Unsupported Debian flavour!')  }
          }
        }
        default:
        {
          $repoprovider = 'apt'
          $sysconfig=false

          $postgresuser='postgres'
          $postgresgroup='postgres'
          $postgreshome='/var/lib/pgsql'
          case $::operatingsystem
          {
            'Ubuntu':
            {
              case $::operatingsystemrelease
              {
                /^14.*$/:
                {
                  $systemd=false
                }
                /^1[68].*$/:
                {
                  $systemd=true
                }
                /^20.*$/:
                {
                  $systemd=true
                }
                default: { fail("Unsupported Ubuntu version! - ${::operatingsystemrelease}")  }
              }
            }
            'Debian':
            {
              case $::operatingsystemrelease
              {
                /^8.*$/:
                {
                  $systemd=false
                }
                /^9.*$/:
                {
                  $systemd=true
                }
                /^10.*$/:
                {
                  $systemd=true
                }
                default: { fail("Unsupported Debian version! - ${::operatingsystemrelease}")  }
              }
            }
            default: { fail('Unsupported Debian flavour!')  }
          }
        }
      }
    }
    default: { fail('Unsupported OS!')  }
  }
}
