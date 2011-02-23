# Class: ntp
#
#   This module manages the ntp service.
#
#   Jeff McCune <jeff@puppetlabs.com>
#   2011-02-23
#
#   Tested platforms:
#    - Debian 6.0 Squeeze
#
# Parameters:
#
#   $servers = [ "0.debian.pool.ntp.org iburst",
#                "1.debian.pool.ntp.org iburst",
#                "2.debian.pool.ntp.org iburst",
#                "3.debian.pool.ntp.org iburst", ]
#
# Actions:
#
#  Installs, configures, and manages the ntp service.
#
# Requires:
#
# Sample Usage:
#
#   class { "ntp": servers => [ 'time.apple.com' ] }
#
# [Remember: No empty lines between comments and class definition]
class ntp($servers=[ "0.debian.pool.ntp.org iburst",
                     "1.debian.pool.ntp.org iburst",
                     "2.debian.pool.ntp.org iburst",
                     "3.debian.pool.ntp.org iburst",],
          $ensure="running",
          $autoupdate=false
) {

  if ! ($ensure in [ "running", "stopped" ]) {
    fail("ensure parameter must be running or stopped")
  }

  if $autoupdate == true {
    $package_ensure = latest
  } elsif $autoupdate == false {
    $package_ensure = present
  } else {
    fail("autoupdate parameter must be true or false")
  }

  case $operatingsystem {
    debian, ubuntu: {
      $supported  = true
      $pkg_name   = [ "ntp" ]
      $svc_name   = "ntp"
      $config     = "/etc/ntp.conf"
      $config_tpl = "ntp.conf.debian.erb"
    }
    default: {
      $supported = false
      notify { "${module_name}_unsupported":
        message => "The ${module_name} module is not supported on ${operatingsystem}",
      }
    }
  }

  if ($supported == true) {

    package { $pkg_name:
      ensure => $package_ensure,
    }

    file { $config:
      ensure => file,
      owner  => 0,
      group  => 0,
      mode   => 0644,
      content => template("${module_name}/${config_tpl}"),
      require => Package[$pkg_name],
    }

    service { "ntp":
      ensure     => $ensure,
      name       => $svc_name,
      hasstatus  => true,
      hasrestart => true,
      subscribe  => [ Package[$pkg_name], File[$config] ],
    }

  }

}