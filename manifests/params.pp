class postgresql::params {

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
        }
        default: { fail("Unsupported RHEL/CentOS version! - ${::operatingsystemrelease}")  }
      }
    }
    default: { fail('Unsupported OS!')  }
  }
}
