class postgresql::params {

  $port_default='5432'

  $log_directory_default='pg_log'
  $log_filename_default='postgresql-%Y%m%d.log'

  $timezone_default='Europe/Andorra'
  #fer 9.2 minim

  case $::osfamily
  {
    'redhat':
    {
      case $::operatingsystem
      {
        'RedHat':
        {
          case $::operatingsystemrelease
          {
            /^6.*$/:
            {
              #TODO: es centos only

              $version_default='9.2'
              #TODO: modificar segons versio
              $datadir_default='/var/lib/pgsql/9.2/data'
              $repoprovider = 'rpm'
              $reposource =  {
                              '9.2' => 'https://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-6-x86_64/pgdg-redhat92-9.2-8.noarch.rpm',
                              }
              $reponame = {
                            '9.2' => 'pgdg-redhat92',
                          }
              $packagename=[ 'postgresql92', 'postgresql92-server' ]
              $servicename = {
                                '9.2' => 'postgresql-9.2',
                              }
              $initdb = {
                          '9.2' => '/usr/pgsql-9.2/bin/initdb',
                        }
              $contrib = {
                          '9.2' => 'postgresql92-contrib',
                        }
              $postgresuser='postgres'
              $postgresgroup='postgres'
              $postgreshome='/var/lib/pgsql'

              $sysconfig=true
            }
            /^7.*$/:
              {
                #TODO: es centos only

                $version_default='9.2'
                #TODO: modificar segons versio
                $datadir_default='/var/lib/pgsql/9.2/data'
                $repoprovider = 'rpm'
                $reposource =  {
                                '9.2' => 'https://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-7-x86_64/pgdg-redhat92-9.2-3.noarch.rpm',
                                }
                $reponame = {
                              '9.2' => 'pgdg-redhat92',
                            }
                $packagename=[ 'postgresql92', 'postgresql92-server' ]
                $servicename = {
                                  '9.2' => 'postgresql-9.2',
                                }
                $initdb = {
                            '9.2' => '/usr/pgsql-9.2/bin/initdb',
                          }
                $contrib = {
                            '9.2' => 'postgresql92-contrib',
                          }
                $postgresuser='postgres'
                $postgresgroup='postgres'
                $postgreshome='/var/lib/pgsql'

                $sysconfig=true
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
              #TODO: es centos only

              $version_default='9.2'
              #TODO: modificar segons versio
              $datadir_default='/var/lib/pgsql/9.2/data'
              $repoprovider = 'rpm'
              $reposource =  {
                              '9.2' => 'http://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-7.noarch.rpm',
                              }
              $reponame = {
                            '9.2' => 'pgdg-centos92',
                          }
              $packagename=[ 'postgresql92', 'postgresql92-server' ]
              $servicename = {
                                '9.2' => 'postgresql-9.2',
                              }
              $initdb = {
                          '9.2' => '/usr/pgsql-9.2/bin/initdb',
                        }
              $contrib = {
                          '9.2' => 'postgresql92-contrib',
                        }
              $postgresuser='postgres'
              $postgresgroup='postgres'
              $postgreshome='/var/lib/pgsql'

              $sysconfig=true
            }
            /^7.*$/:
            {
              #TODO: es centos only

              $version_default='9.2'
              #TODO: modificar segons versio
              $datadir_default='/var/lib/pgsql/9.2/data'
              $repoprovider = 'rpm'
              $reposource =  {
                              '9.2' => 'https://download.postgresql.org/pub/repos/yum/9.2/redhat/rhel-7-x86_64/pgdg-centos92-9.2-3.noarch.rpm',
                              }
              $reponame = {
                            '9.2' => 'pgdg-centos92',
                          }
              $packagename=[ 'postgresql92', 'postgresql92-server' ]
              $servicename = {
                                '9.2' => 'postgresql-9.2',
                              }
              $initdb = {
                          '9.2' => '/usr/pgsql-9.2/bin/initdb',
                        }
              $contrib = {
                          '9.2' => 'postgresql92-contrib',
                        }
              $postgresuser='postgres'
              $postgresgroup='postgres'
              $postgreshome='/var/lib/pgsql'

              $sysconfig=true
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
