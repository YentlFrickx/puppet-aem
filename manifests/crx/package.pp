# == Define: aem::crx::package
#
# Used to install a CRX Package.
#
define aem::crx::package (
  $ensure      = 'present',
  $group       = 'aem',
  $home        = undef,
  $pkg_group   = undef,
  $pkg_name    = undef,
  $pkg_version = undef,
  $password    = undef,
  $source      = undef,
  $type        = undef,
  $user        = 'aem',
  $username    = undef,
) {

  validate_re($ensure, '^(present|installed|absent)$',
    "${ensure} is not supported for ensure. Allowed values are: 'present', 'installed' or 'absent'.")

  validate_absolute_path($home)

  if $ensure != 'absent' {
    validate_absolute_path($source)
  }

  case $type {
    'api': {

      if $username == undef {
        fail("Username is required when type == 'api'")
      }
      if $password == undef {
        fail("Password is required when type == 'api'")
      }

      if $pkg_group == undef {
        fail("Package Group is required when type == 'api'")
      }

      if $pkg_version == undef {
        fail("Package Version is required when type == 'api'")
      }

      include ::ruby::dev
      include ::aem

      package { 'crx_packmgr_api_client' :
        ensure   => $aem::crx_packmgr_api_client_ver,
        provider => $aem::puppetgem
      }

      package { 'xml-simple' :
        ensure   => $aem::xmlsimple_ver,
        provider => $aem::puppetgem
      }

      aem_crx_package { $name :
        ensure   => $ensure,
        group    => $pkg_group,
        home     => $home,
        name     => $pkg_name,
        password => $password,
        source   => $source,
        username => $username,
        version  => $pkg_version
      }

      Class['ruby::dev']
      -> Class['aem']
      -> Package['xml-simple']
      -> Package['crx_packmgr_api_client']
      -> Aem_Crx_Package[$name]

    }
    'file': {

      case $ensure {
        /^(present|installed)$/ : { $_ensure = 'present' }
        'absent': { $_ensure = $ensure }
        default: { $_ensure = 'pesent'}
      }
      aem::crx::package::file { $name :
        ensure => $_ensure,
        group  => $group,
        home   => $home,
        source => $source,
        user   => $user,
      }
    }
    default: {
      fail("${type} is not supported for type. Allowed values are 'api' and 'type'.")
    }
  }
}