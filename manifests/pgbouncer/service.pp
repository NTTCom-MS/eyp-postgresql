class postgresql::pgbouncer::service inherits postgresql::pgbouncer {

  $is_docker_container_var=getvar('::eyp_docker_iscontainer')
  $is_docker_container=str2bool($is_docker_container_var)

  if( $is_docker_container==false or
      $postgresql::pgbouncer::manage_docker_service)
  {
    if($postgresql::pgbouncer::manage_service)
    {
      service { $postgresql::params::pgbouncer_service_name:
        ensure     => $postgresql::pgbouncer::service_ensure,
        enable     => $postgresql::pgbouncer::service_enable,
        hasstatus  => true,
        hasrestart => true,
      }
    }
  }
}
