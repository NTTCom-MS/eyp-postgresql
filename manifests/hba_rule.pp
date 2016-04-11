define postgresql::hba_rule (
                              $user,
                              $database,
                              $address,
                              $type        = 'host',
                              $auth_method = 'md5',
                              $auth_option = undef, # TODO: sera clau valor, fer hash
                              $description = $name,
                              $order       = '01',
                            ) {

  concat::fragment{ "header pg_hba ${datadir}":
    target  => "${postgresql::datadir}/pg_hba.conf",
    content => template("${module_name}/hba/rule.erb"),
    order   => $order,
  }

}
