class postgresql::service inherits postgresql {

  $is_docker_container_var=getvar('::eyp_docker_iscontainer')
  $is_docker_container=str2bool($is_docker_container_var)

  #raspbian postgresql.service
  if($postgresql::params::repoprovider=='raspbian10')
  {
    $postgres_service_name='postgresql@11-main.service'
  }
  else
  {
    $postgres_service_name=$postgresql::params::servicename[$postgresql::version]
  }

  if( $is_docker_container==false or
      $postgresql::manage_docker_service)
  {
    if($postgresql::manage_service)
    {
      exec { 'check pending restart':
        command => '/bin/bash -c \'echo RESTART NEEDED\'',
        unless  => '/usr/local/bin/check_postgres_pending_restart',
      }

      if($postgresql::restart_if_needed)
      {
        Exec['check pending restart'] {
          notify  => Service[$postgres_service_name],
        }
      }

      service { $postgres_service_name:
        ensure  => $postgresql::ensure,
        enable  => $postgresql::enable,
        require => Exec['check pending restart'],
      }
    }
  }
}
