class postgresql::service inherits postgresql {

  $is_docker_container_var=getvar('::eyp_docker_iscontainer')
  $is_docker_container=str2bool($is_docker_container_var)

  if( $is_docker_container==false or
      $postgresql::manage_docker_service)
  {
    if($postgresql::manage_service)
    {
      service { $postgresql::params::servicename[$postgresql::version]:
        ensure => $postgresql::ensure,
        enable => $postgresql::enable,
      }

      
    }
  }
}
