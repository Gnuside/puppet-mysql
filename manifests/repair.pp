
class mysql::repair {  
  include mysql
  
  exec { "repair":
    refreshonly => true,
    command => "mysqlrepair -hlocalhost --auto-repair --check-upgrade --all-databases -r -uroot -p${mysql_password}",
  } 
}
  