class postgresql::params {

  $port_default='5432'

  $log_directory_default='pg_log'
  $log_filename_default='postgresql-%Y%m%d.log'

  $log_timezone_default='Europe/Andorra'
  #fer 9.2 minim

  case $::osfamily
  {
    'redhat':
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
          $postgresuser='postgres'
          $postgresgroup='postgres'
          $postgreshome='/var/lib/pgsql'
        }
        default: { fail("Unsupported RHEL/CentOS version! - ${::operatingsystemrelease}")  }
      }
    }
    default: { fail('Unsupported OS!')  }
  }
}
