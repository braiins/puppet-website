# == Define: website::gunicorn_systemd
#
# Installs systemd service for gunicorn.
# This define should not be used directly, use website::gunicorn with service type instead
#
# === Parameters
#
# [*user*]
#  see website::gunicorn::user
# [*web_project_root*]
#  see website::gunicorn::web_project_root
# [*web_project_venv_path*]
#  see website::gunicorn::web_project_venv_path
# [*web_project_path*]
#  see website::gunicorn::web_project_path
# [*wsgi_module_name*]
#  see website::gunicorn::wsgi_module_name
# [*django_socket_path*]
#  see website::gunicorn::django_socket_path
# [*log_path*]
#  see website::gunicorn::log_path
# [*ensure_running*]
#  see website::gunicorn::ensure_running
# [*gunicorn_pid_file*]
#  pid file of the gunicorn
# [*gunicorn_workers*]
#  number of workers that will handle web requests
# [*service_opts*]
#  see website::gunicorn::service_opts for details
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2016 Braiins Systems s.r.o.
#
define website::gunicorn_systemd(
  $user,
  $web_project_root,
  $web_project_venv_path,
  $web_project_path,
  $wsgi_module_name,
  $django_socket_path,
  $log_path,
  $ensure_running=true,
  $gunicorn_pid_file,
  $gunicorn_workers,
  $service_opts
) {
  $user_home = getparam(User[$user], 'home')
  $systemd_service = $title

  # map the parameter onto string supported by supervisor::program
  $ensure_process_str = $ensure_running ? {true => 'running', false => 'stopped'}
  $gunicorn_exec="${web_project_venv_path}/bin/gunicorn"

  # supervisor managed applications always have 'supervisord'
  # tag. Therefore, we have to sort the logs based on message contents
  base::rsyslog::app_log_filter { $systemd_service:
    order           => '10',
    log_path        => $log_path,
    app_name_prefix => $systemd_service,
  }

  file { "/etc/systemd/system/${systemd_service}.service":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    content => template('website/gunicorn_systemd.service.erb'),
  } ->
  service { $systemd_service:
      provider => systemd,
      ensure => $ensure_process_str,
      enable => false,
  }
}
