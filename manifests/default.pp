exec { "apt-get update":
    path => "/usr/bin",
}

#
# Install apache, php, mysql
#

package { ["apache2", "mysql-server", "mysql-client"]:
    ensure => present,
    require => Exec["apt-get update"],
}

package { ["php5-common", "libapache2-mod-php5", "php5-cli", "php-apc", "php5-mysql"]:
    ensure => present,
    notify => Service["apache2"],
    require => [Exec["apt-get update"], Package["mysql-client"], Package["apache2"]],
}

service { "apache2":
    ensure => "running",
    require => Package["apache2"],
}

service { "mysql":
    ensure => "running",
    require => Package["mysql-server"],
}


#
# Enable mod_rewrite
#

exec { "/usr/sbin/a2enmod rewrite":
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/rewrite.load",
    notify => Service["apache2"],
    require => Package["apache2"],
}


#
# Make sure Apache is running as vagrant user
#

exec { "ApacheUserChange" :
  command => "/bin/sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/' /etc/apache2/envvars",
  onlyif  => "/bin/grep -c 'APACHE_RUN_USER=www-data' /etc/apache2/envvars",
  require => Package["apache2"],
  notify  => Service["apache2"],
}

exec { "ApacheGroupChange" :
  command => "/bin/sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars",
  onlyif  => "/bin/grep -c 'APACHE_RUN_GROUP=www-data' /etc/apache2/envvars",
  require => Package["apache2"],
  notify  => Service["apache2"],
}

exec { "apache_lockfile_permissions" :
  command => "/bin/chown -R vagrant:www-data /var/lock/apache2",
  require => Package["apache2"],
  notify  => Service["apache2"],
}



#
# Build dir structure for our default virtual host
#

file { ["/vagrant/vhosts"]:
    ensure => "directory",
    require => [Package["apache2"]],
    notify => Service["apache2"],
}

file { ["/vagrant/vhosts/default"]:
    ensure => "directory",
    require => File["/vagrant/vhosts"],
}

file { ["/vagrant/vhosts/default/web-root", "/vagrant/vhosts/default/logs", "/vagrant/vhosts/default/uploads"]:
    ensure => "directory",
    require => File["/vagrant/vhosts/default"],
}

file { "/var/www/vhosts":
    ensure => "link",
    target => "/vagrant/vhosts",
    require => [File["/vagrant/vhosts/default"],Package["apache2"]],
    notify => Service["apache2"],
    replace => yes,
    force => true,
}



#
# Setup our sites-enabled directory
#

file { "/etc/apache2/sites-enabled":
  ensure => "link",
  target => "/vagrant/sites-enabled",
  require => Package["apache2"],
  notify => Service["apache2"],
  replace => yes,
  force => true,
}
