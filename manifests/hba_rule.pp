define postgresql::hba_rule (
                              $user,
                              $database,
                              $address,
                              $type        = 'host',
                              $auth_method = 'md5',
                              $auth_option = undef, # TODO: sera clau valor, fer hash
                              $description = $name,
                              $order       = '01',
                              $datadir     = $postgresql::datadir,
                            ) {
  include ::postgresql

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$postgresql::version]
  }
  else
  {
    $datadir_path = $datadir
  }

  concat::fragment{ "rule pg_hba ${datadir_path} ${user} ${description} ${address} ${database}":
    target  => "${postgresql::datadir_path}/pg_hba.conf",
    content => template("${module_name}/hba/rule.erb"),
    order   => $order,
  }

}
