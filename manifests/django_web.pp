# == Define: base::misc::django_web
#
# Generic installation and configuration of Django based website with
# nginx reverse proxy.
#
#
# === Parameters
# [*user*]
#   user running django web
# [*aliases*]
# [*revision*]
#   revision of the web project to be cloned from the git repository
# [*http_port*]
# [*https_port*]
# [*redirect_to_https*]
#   Redirects from http to https (disabled by default)
# [*main_project_git_uri*]
#   Uri of the main project of this Django website
# [*main_project_name*]
#   Name of the project how it should be cloned from git
# [*main_module_name*]
#   Name of the main module within the Django project (required by settings)
# [*revision*]
#   revision of the main Django project to be checked out
# [*db_host*]
#   database host that has the database for the Django application. If
#   undefined, or set to 'localhost' or set to loopback interface
#   address, the database will be created on the local machine
# [*db_port*]
#   database listening port
# [*db_name*],
#   name of the database
# [*db_user*]
#   database user for the Django application
# [*db_password*]
#   database password
# [*debug*]
#   enable/disable debugging output of the application
# [*django_secret_key*]
#   secret key for the Django
# [*settings_location_filename*]
#   name of the file that stores the local settings of the application
#   (defaults to settings_location.py
# [*settings_location_template*]
#   additional template appended to the base settings_location
#   template. The basic template contains only database login
#   credentials and debugging control option
# [*settings_location_values*]
#   additional dictionary for custom settings_location template
# [*nginx_priority*]
#   priority of the nginx site
# [*nginx_server_opts*]
#   options for server section of this website. Currently, it defaults
#   to additional headers
# [*admin_allowed_hosts*]
#   list of hosts allowed for accessing the admin interface
# [*nginx_locations*]
#   the default locations can be replaced completely. By default, it
#   covers only the catch-all location (redirected to the server) and
#   admin interface restricted a list of specified hosts (see
#   admin_allowed_hosts)
# [*error_page*]
#   see website::vhost_nginx::error_page parameter for details
# [*overlimit_error_page*]
#   see website::vhost_nginx::overlimit_error_page parameter for details
#
# === Examples
#
# website::django_web { 'example.net':
#   aliases              => 'example.org',
#   http_port            => '80',
#   https_port           => undef,
#   redirect_to_https    => false,
#   main_project_git_uri => 'http://example.net/websites/example.git',
#   main_project_name    => 'example.org',
#   main_module_name     => 'example',
#   wsgi_module_name     => 'wsgi',
#   revision             => 'master',
#   db_host              => 'localhost',
#   db_port              => '5432',
#   db_name              => 'exampledb',
#   db_user              => 'adminuser',
#   db_password          => 'adminpassword',
#   django_secret_key    => 'supersecretdjangokey',
#   priority             => '60',
#   admin_allowed_hosts  => ['1.2.3.4/32'],
# }
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2015 Braiins Systems s.r.o.
#
define website::django_web(
  $user='admin',
  $aliases=[],
  $http_port,
  $https_port,
  $redirect_to_https=false,
  $main_project_git_uri,
  $main_project_name,
  $main_module_name,
  $revision,
  $compile_messages=true,
  $db_host=undef,
  $db_port,
  $db_name,
  $db_user,
  $db_password,
  $debug='False',
  $django_secret_key,
  $settings_location_filename='settings_location.py',
  $settings_location_template='website/empty_template.erb',
  $settings_location_values=undef,
  $nginx_priority='50',
  $nginx_server_opts={
    'add_header' => [
                     "Access-Control-Allow-Origin '*'",
                     'Access-Control-Allow-Credentials true',
                     "Access-Control-Allow-Headers 'Content-Type, Accept, X-Requested-With'",
                     "Access-Control-Allow-Methods 'GET, POST, OPTIONS, PUT, DELETE'",
                     ],
  },
  $admin_allowed_hosts=[],
  $nginx_locations={
    '/' => {
      'proxy_pass'   => true,
    },
    '~* admin' => {
      'proxy_pass'   => true,
      'extra_opts'   => {
        'allow'   =>  $admin_allowed_hosts,
        'deny'    =>  'all',
        'rewrite' => '^(.*) $1 break',
      },
    },
  },
  $error_page='',
  $overlimit_error_page='',
  ) {

  if $redirect_to_https and $https_port == undef  {
    fail("Cannot enable redirect to HTTPS when https port not specified")
  }

  # Web project startup script -> template configuration parameters
  $user_home = getparam(User[$user], 'home')
  $web_project_root = "${user_home}/${title}"
  $web_project_venv_path = "${web_project_root}/.env"
  $web_project_path = "${web_project_root}/${main_project_name}"
  $web_project_settings_location = "${web_project_path}/${main_module_name}/${settings_location_filename}"

  # Global Git repository setup
  Vcsrepo {
    ensure   => present,
    provider => git,
    owner    => $user,
    group    => $user,
    require  => [ Package['git'], User[$user], ]
  }
  Python::Requirements {
    virtualenv  => $web_project_venv_path,
    forceupdate => true,
    owner       => $user,
    group       => $user,
  }
  if ($db_host == 'localhost') or ($db_host == $::ipaddress_lo)
  or ($db_host == undef) {
    # Create database and user/owner
    postgresql::server::db { $db_name:
      user     => $db_user,
      password => $db_password,
    }
  }
  # TODO: make mode more restrictive - 0750
  file { $web_project_root:
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0755'
  } ->
  vcsrepo { $web_project_path:
    source   => $main_project_git_uri,
    revision => $revision,
  } ->
  python::virtualenv { $web_project_venv_path:
    ensure       => present,
    version      => 'system',
    systempkgs   => false,
    owner        => $user,
    group        => $user,
    cwd          => $web_project_root,
    timeout      => 0,
  } ->
  python::requirements { "${web_project_path}/requirements.txt":
  } ->
  file { $web_project_settings_location:
    content => template('website/settings_location_base.py.erb', $settings_location_template),
    owner   => $user,
    group   => $user,
    mode    => '0640',
  } ->
  website::gunicorn { $title:
    user                  => $user,
    web_project_root      => $web_project_root,
    web_project_venv_path => $web_project_venv_path,
    web_project_path      => $web_project_path,
    django_socket_path    => "${web_project_root}/django.sock",
    main_module_name      => $main_module_name,
  }

  # Default settings for nginx vhost configurations (shared for http and https)
  Website::Vhost_nginx {
    require              => Website::Gunicorn[ $title ],
    serveraliases        => flatten([$title, $aliases]),
    priority             => $nginx_priority,
    upstream_socket_path => getparam(Website::Gunicorn[ $title ], 'django_socket_path'),
    error_page           => $error_page,
    overlimit_error_page => $overlimit_error_page,
    locations            => $nginx_locations,
    server_opts          => $nginx_server_opts,
  }

  if $redirect_to_https {
    nginx::vhost { "http-${title}":
      priority      => $nginx_priority,
      docroot       => undef,
      port          => $http_port,
      serveraliases => flatten([$title, $aliases]),
      options       => {
        # NOTE: the server_name is nginx variable (not expanded by puppet)
        'redirect_url' => 'https://$host',
      },
      create_docroot => false,
      template       => 'nginx/vhost/vhost_redirect.erb',
    }
  }
  else {
    website::vhost_nginx { "http-${title}":
      port => $http_port,

    }
  }
  if $https_port {
    website::vhost_nginx { "https-${title}":
      port => $https_port,
    }
  }
}
