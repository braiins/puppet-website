# == Define: website::vhost_nginx
#
# Generates a nginx vhost configuration for a Django based web application.
#
# === Parameters
#
# [*port*]
#    port where this vhost should listen
# [*priority*]
#    priority of the site configuration file
# [*serveraliases*]
#    list of aliases of the vhost
# [*docroot*]
#    document root of the website
# [*upstream_socket_path*]
#    socket path of the upstream application
# [*error_page*]
#   specifies the name of the custom error page. It is user
#   responsibility to deploy the error page into website document root
#   directory under 'error/' subdirectory
# [*overlimit_error_page*]
#    same as above, the page is only meant for the rate limitter
#    related errors
#
# === Examples
#
# website::vhost_nginx { 'example.net':
#   require              => Website::Gunicorn[ 'example.net' ],
#   upstream_socket_path => '/home/admin/example.net/django.sock'),
#   error_page           => $error_page,
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
define website::vhost_nginx(
  $port,
  $priority='50',
  $locations,
  $serveraliases=[],
  $docroot=undef,
  $upstream_socket_path,
  $error_page='',
  $overlimit_error_page='',
  $server_opts,
) {
  nginx::vhost { $title:
    port           => $port,
    priority       => $priority,
    docroot        => $docroot,
    create_docroot => false,
    serveraliases  => $serveraliases,
    template       => 'website/nginx_site.conf.erb',
    options        => {
      'upstream_web'         => "upstream-${port}-${title}",
      'upstream_socket_path' => $upstream_socket_path,
      'locations'            => $locations,
      'error_page'           => $error_page,
      'overlimit_error_page' => $overlimit_error_page,
      'server_opts'          => $server_opts,
    }
  }
}
