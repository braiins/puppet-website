# == Define: website::gunicorn_supervisord
#
# Installs configuration for gunicorn managed by supervisord.
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
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2016 Braiins Systems s.r.o.
#
define website::gunicorn_supervisord(
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
) {
  $user_home = getparam(User[$user], 'home')
  $supervisor_program = $title

  # map the parameter onto string supported by supervisor::program
  $ensure_process_str = $ensure_running ? {true => 'running', false => 'stopped'}

  # supervisor managed applications always have 'supervisord'
  # tag. Therefore, we have to sort the logs based on message contents
  base::rsyslog::app_log_filter_by_msg { $supervisor_program:
    order           => '10',
    log_path        => $log_path,
    msg_contains    => $supervisor_program,
  }

  supervisord::program { $supervisor_program:
    command                  => "${web_project_venv_path}/bin/gunicorn -p ${gunicorn_pid_file} ${wsgi_module_name}:application -b unix:${django_socket_path} --timeout 100 --workers ${gunicorn_workers} --worker-connections 100 --max-requests 50000 ",
    autostart                => true,
    # NOTE: autorestart is not bool but string as it may have values:
    # true/false/unexpected
    autorestart              => 'true',
    redirect_stderr          => true,
    user                     => $user,
    environment              => {
      'HOME' => $user_home,
      'USER' => $user,
    },
    directory                => $web_project_path,
    ensure_process           => $ensure_process_str,
    stdout_logfile           => 'syslog',
    stderr_logfile           => 'syslog',
  }
}
