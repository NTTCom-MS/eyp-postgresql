class postgresql::pgstatsstatements (
                                      $version       = $postgresql::version,
                                      $datadir       = $postgresql::datadir,
                                      $track_utility = true,
                                      $track         = 'all',
                                      $max           = '10000',
                                      $dbname        = undef,
                                      $port          = $postgresql::port,
                                    ) inherits postgresql::params {
  if($postgresql::params::contrib[$version]==undef)
  {
    fail('unable to install postgis - unsupported version')
  }

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$version]
  }
  else
  {
    $datadir_path = $datadir
  }

  if(!defined(Package[$postgresql::params::contrib[$version]]))
  {
    package { $postgresql::params::contrib[$version]:
      ensure  => 'installed',
      require => Class['::postgresql::config'],
      before  => Class['::postgresql::service'],
    }

    if($dbname!=undef)
    {
      postgresql::pgstatsstatements::extension{ $dbname:
        require => Package[$postgresql::params::contrib[$version]],
        port    => $port,
      }
    }
  }

  concat::fragment{ "pg_stats_statement postgresql ${datadir_path}":
    target  => "${datadir_path}/postgresql.conf",
    content => template("${module_name}/pgstatsstatements/pgstatsstatements.erb"),
    order   => '80',
  }
}
