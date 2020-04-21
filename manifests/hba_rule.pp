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

  concat::fragment{ "${type} ${database} ${user} ${address} ${auth_method} rule pg_hba ${datadir_path}  ${description}":
    target  => "${postgresql::datadir_path}/pg_hba.conf",
    content => template("${module_name}/hba/rule.erb"),
    order   => $order,
  }

}
