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
# [*wsgi_module_name*]
#  name of the WSGI module
# [*django_socket_path*]
#  socket path for Django
# [*log_path*]
#  base path for storing logs
# [*ensure_running*]
#  true=>ensure that the gunicorn process is running when true, false=>ensure the process is stopped
# [*service_type*]
#  determines what type of service will the gunicorn instance use
#  (systemd or supervisord. Acceptable values are: 'systemd' or
#  'supervisord'.
# [*service_opts*]
#  service specific options
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
  $wsgi_module_name='wsgi',
  $django_socket_path,
  $log_path="/var/log/${title}",
  $ensure_running=true,
  $service_type='supervisord',
  $service_opts=undef,
) {
  $gunicorn_title = "gunicorn-${title}"
  $gunicorn_pid_file = "${web_project_root}/django.pid"
  # Recommended number of workers is 2 * CPUCOUNT + 1
  $gunicorn_workers = 2 * $processorcount + 1

  python::pip { $gunicorn_title:
    pkgname    => 'gunicorn',
    virtualenv => $web_project_venv_path,
  }

  $service_params = {
    $gunicorn_title => {
      'user'                  => $user,
      'web_project_root'      => $web_project_root,
      'web_project_venv_path' => $web_project_venv_path,
      'web_project_path'      => $web_project_path,
      'wsgi_module_name'      => $wsgi_module_name,
      'django_socket_path'    => $django_socket_path,
      'log_path'              => $log_path,
      'ensure_running'        => $ensure_running,
      'gunicorn_pid_file'     => $gunicorn_pid_file,
      'gunicorn_workers'      => $gunicorn_workers,
      'service_opts'          => $service_opts,
    },
  }
  create_resources("website::gunicorn_${service_type}", $service_params)
}
