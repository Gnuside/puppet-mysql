

## ENGLOBE MYSQL
class mysql {
    include mysql::install, mysql::service
}

class mysql::params {
  $data_path = "/var/lib/mysql"
}


## INSTALL MYSQL
class mysql::install {
    include mysql::params

    package { "mysql-server": ensure => installed }
    package { "mysql-client": ensure => installed }
}

## RUN MYSQL
class mysql::service {
    include mysql::params

  service { "mysql":
    enable => true,
    ensure => running,
    hasstatus => true,
    require => Package["mysql-server"],
  }

  #file { "/var/lib/mysql/my.cnf":
  #	owner => "mysql", group => "mysql",
  #	      source => "puppet:///mysql/my.cnf",
  #	      notify => Service["mysqld"],
  #	      require => Package["mysql-server"],
  #   }

  #  file { "/etc/my.cnf":
  #	require => File["/var/lib/mysql/my.cnf"],
  #		ensure => "/var/lib/mysql/my.cnf",
  #   }

}


define mysql::password (
  $password = "",
  $username = "root"
) {
  include mysql
  
  exec { "mysql::password::set-mysql-password ${password}":
    unless => "mysqladmin -u${username} -p'${password}' status",
    path => ["/bin", "/usr/bin"],
    command => "mysqladmin -u${username} password '${password}'",
    require => Class['mysql::service']
  }
}

define mysql::database_create ( $username, $password, $root_password ) {
  include mysql

  $create_sql = "create database ${name};"
  $grant_sql = "grant all on ${name}.* to ${username}@localhost identified by '$password';"


   exec { "mysql::database_create::create-db ${name}":
     unless => "/usr/bin/mysql -uroot -p${root_password} ${name}",
     command => "/usr/bin/mysql -uroot -p${root_password} -e \"${create_sql}\"",
     require => Class['mysql::service']
   }

   exec { "mysql::database_create::grant-db ${name}":
     unless => "/usr/bin/mysql -u${username} -p${password} ${name}",
     command => "/usr/bin/mysql -uroot -p${root_password} -e \"${grant_sql}\"",
     require => [Class["mysql::service"], Exec["mysql::database_create::create-db ${name}"]]
   }
}


define mysql::database_seed ( $username, $password, $root_password, $seed_file, $final_table ) {
  include mysql

  $database = $name

  exec { "mysql::database_seed ${database}":
    require => Mysql::Database_create["${database}"],
    unless => "test -f ${seed_file} && \
      mysql --batch -u${username} -p${password} \
      -e 'SHOW TABLES' ${database} | grep -q '^${final_table}$'",
    command => "cat ${seed_file} | \
      mysql --batch -u${username} -p${password} ${database}",
  }
}
