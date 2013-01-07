
## INSTALL MYSQL

class mysql {
  $data_path = "/var/lib/mysql"
  package { "mysql-server": ensure => installed }
  package { "mysql-client": ensure => installed }

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
  
  exec { "set-mysql-password":
    unless => "mysqladmin -u${username} -p'${password}' status",
    path => ["/bin", "/usr/bin"],
    command => "mysqladmin -u${username} password '${password}'",
    require => Service['mysql']
  }
}
