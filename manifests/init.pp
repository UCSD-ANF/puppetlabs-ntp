# Class: ntp
#
#   This module manages the ntp service.
#
#   Jeff McCune <jeff@puppetlabs.com>
#   2011-02-23
#
#   Tested platforms:
#    - Debian 6.0 Squeeze
#    - CentOS 5.4
#    - Amazon Linux 2011.09
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
#   class { "ntp":
#     servers    => [ 'time.apple.com' ],
#     autoupdate => false,
#   }
#
# [Remember: No empty lines between comments and class definition]
class ntp($servers="UNSET",
          $ensure="UNSET",
          $autoupdate=false
) {

  if $autoupdate == true {
    $package_ensure = $::operatingsystem ? {
      'Solaris' => 'present', # autoupdate not possible on Solaris
      default   => 'latest',
    }
  } elsif $autoupdate == false {
    $package_ensure = present
  } else {
    fail("autoupdate parameter must be true or false")
  }

  case $::operatingsystem {
    debian, ubuntu: {
      $supported  = true
      $pkg_name   = [ "ntp" ]
      $svc_name   = "ntp"
      $svc_ensure = $ensure ? {
        'UNSET' => 'running',
        default => $ensure,
      }
      $config     = "/etc/ntp.conf"
      $config_tpl = "ntp.conf.debian.erb"
      if ($servers == "UNSET") {
        $servers_real = [ "0.debian.pool.ntp.org iburst",
                          "1.debian.pool.ntp.org iburst",
                          "2.debian.pool.ntp.org iburst",
                          "3.debian.pool.ntp.org iburst", ]
      } else {
        $servers_real = $servers
      }
    }
    centos, redhat, oel, linux: {
      $supported  = true
      $pkg_name   = [ "ntp" ]
      $svc_name   = "ntpd"
      $svc_ensure = $ensure ? {
        'UNSET' => 'running',
        default => $ensure,
      }
      $config     = "/etc/ntp.conf"
      $config_tpl = "ntp.conf.el.erb"
      if ($servers == "UNSET") {
        $servers_real = [ "0.centos.pool.ntp.org",
                          "1.centos.pool.ntp.org",
                          "2.centos.pool.ntp.org", ]
      } else {
        $servers_real = $servers
      }
    }
    solaris: {
      $supported  = true
      $pkg_name   = [ 'SUNWntpr', 'SUNWntpu' ]
      $svc_name   = 'svc:/network/ntp:default'
      $svc_ensure = $virtual ? {
        'zone'  => 'stopped', # Solaris zones cannot run ntp
        default => $ensure ? {
          'UNSET' => 'running',
          default => $ensure,
        },
      }
      $config     = '/etc/inet/ntp.conf'
      $config_tpl = 'ntp.conf.solaris.erb'
      if ($servers == 'UNSET') {
        $servers_real = [ '0.pool.ntp.org iburst',
                          '1.pool.ntp.org iburst',
                          '2.pool.ntp.org iburst', ]
      } else {
        $servers_real = $servers
      }
    }
    default: {
      $supported = false
      notify { "${module_name}_unsupported":
        message => "The ${module_name} module is not supported on ${::operatingsystem}",
      }
    }
  }

  if ! ($svc_ensure in [ "running", "stopped" ]) {
    fail("ensure parameter must be running or stopped")
  }

  if ($supported == true) {

    if $::operatingsystem == 'solaris' {
      package { $pkg_name:
        ensure   => $package_ensure,
        provider => 'sun', # force the system package provider, not pkgutil
      }
    } else {
      package { $pkg_name:
        ensure => $package_ensure,
      }
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
      ensure     => $svc_ensure,
      name       => $svc_name,
      hasstatus  => true,
      hasrestart => true,
      subscribe  => [ Package[$pkg_name], File[$config] ],
    }

  }

}
