# == Class: website
#
# Installs system wide packages shared by all websites
#
# === Parameters
#
#
# === Variables
#
#
# === Examples
#
#  class { 'website':
#  }
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2015 Braiins Systems s.r.o.
#
class website {
  package { 'gettext':
    ensure => present
  }
}
