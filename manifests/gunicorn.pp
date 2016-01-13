# == Define: website::gunicorn
#
# Installs and manages gunicorn for the current website.  The gunicorn
# is installed into the virtualenv specific for the website and
# managed by supervisor.
#
# === Parameters
#
# [*user*]
#  user running this website instance
# [*web_project_root*]
#  root directory that contains the website project
# [*web_project_venv_path*]
#  python virtual env path of the website project
# [*web_project_path*]
#  path to the main project of the website
#
# === Examples
#
#  website::gunicorn { $title:
#    user                  => $user,
#    web_project_root      => $web_project_root,
#    web_project_venv_path => $web_project_venv_path,
#    web_project_path      => $web_project_path,
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
define website::gunicorn(
  $user,
  $web_project_root,
  $web_project_venv_path,
  $web_project_path,
  $main_module_name,
  $django_socket_path,
) {
  $user_home = getparam(User[$user], 'home')
  $gunicorn_pid_file = "${web_project_root}/django.pid"
  # Recommended number of workers is 2 * CPUCOUNT + 1
  $gunicorn_workers = 2 * $processorcount + 1
  $supervisor_program = "gunicorn-${title}"

  $log_path = "/var/log/${title}"

  # supervisor managed applications always have 'supervisord'
  # tag. Therefore, we have to sort the logs based on message contents
  base::rsyslog::app_log_filter_by_msg { $supervisor_program:
    order           => '10',
    log_path        => $log_path,
    msg_contains    => $supervisor_program,
  }

  python::pip { "gunicorn-${title}":
    pkgname    => 'gunicorn',
    virtualenv => $web_project_venv_path,
  } ->
  supervisord::program { $supervisor_program:
    command                  => "${web_project_venv_path}/bin/gunicorn -p ${gunicorn_pid_file} ${main_module_name}.wsgi -b unix:${django_socket_path} --timeout 100 --workers ${gunicorn_workers} --worker-connections 100 --max-requests 50000 ",
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
    stdout_logfile => 'syslog',
    stderr_logfile => 'syslog',
  }
}
