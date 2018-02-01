class postgresql::params {

  $port_default='5432'

  $log_directory_default='pg_log'
  $log_filename_default='postgresql-%Y%m%d.log'

  $timezone_default='Europe/Andorra'
  #fer 9.2 minim

  $version_default='9.2'

  case $::osfamily
  {
    'redhat':
    {
      $repoprovider = 'rpm'
      $sysconfig=true

      $postgresuser='postgres'
      $postgresgroup='postgres'
      $postgreshome='/var/lib/pgsql'

      $datadir_default = {
                            '9.2' => '/var/lib/pgsql/9.2/data',
                            '9.6' => '/var/lib/pgsql/9.6/data',
                        }

      $packagename= {
                      '9.2' => [ 'postgresql92', 'postgresql92-server' ],
                      '9.6' => [ 'postgresql96', 'postgresql96-server' ],
                    }

      $servicename = {
                        '9.2' => 'postgresql-9.2',
                        '9.6' => 'postgresql-9.6',
                      }

      $pidfile = {
                        '9.2' => '/var/lock/subsys/postgresql-9.2',
                        '9.6' => undef,
                      }
      $initdb = {
                  '9.2' => '/usr/pgsql-9.2/bin/initdb',
                  '9.6' => '/usr/pgsql-9.6/bin/initdb',
                }
      $contrib = {
                  '9.2' => 'postgresql92-contrib',
                  '9.6' => 'postgresql96-contrib',
                }

      case $::operatingsystem
      {
        'RedHat':
        {
          case $::operatingsystemrelease
          {
            /^6.*$/:
            {
              $systemd=false
              $reposource =  {
                              '9.2' => 'https://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-6-x86_64/pgdg-redhat92-9.2-8.noarch.rpm',
                              '9.6' => 'https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-redhat96-9.6-3.noarch.rpm',
                              }
              $reponame = {
                            '9.2' => 'pgdg-redhat92',
                            '9.6' => 'pgdg-redhat96',
                          }
            }
            /^7.*$/:
              {
                $systemd=true
                $reposource =  {
                                '9.2' => 'https://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-7-x86_64/pgdg-redhat92-9.2-3.noarch.rpm',
                                '9.6' => 'https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm',
                                }
                $reponame = {
                              '9.2' => 'pgdg-redhat92',
                              '9.6' => 'pgdg-redhat96',
                            }
              }
            default: { fail("Unsupported RHEL version! - ${::operatingsystemrelease}")  }
          }
        }
        'CentOS':
        {
          case $::operatingsystemrelease
          {
            /^6.*$/:
            {
              $systemd=false
              $reposource =  {
                              '9.2' => 'http://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-7.noarch.rpm',
                              '9.6' => 'https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-centos96-9.6-3.noarch.rpm',
                              }
              $reponame = {
                            '9.2' => 'pgdg-centos92',
                            '9.6' => 'pgdg-centos96',
                          }

            }
            /^7.*$/:
            {
              $systemd=true
              $reposource =  {
                              '9.2' => 'https://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-7-x86_64/pgdg-centos92-9.2-3.noarch.rpm',
                              '9.6' => 'https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm',
                              }
              $reponame = {
                            '9.2' => 'pgdg-centos92',
                            '9.6' => 'pgdg-centos96',
                          }
            }
            default: { fail("Unsupported CentOS version! - ${::operatingsystemrelease}")  }
          }
        }
        default: { fail('Unsupported')}
      }
    }
    default: { fail('Unsupported OS!')  }
  }
}
