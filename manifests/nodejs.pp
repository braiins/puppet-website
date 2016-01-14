# == Define: website::nodejs
#
# Installs:
#  - nodejs into the python virtual environment
#  - all required npm packages
#
# === Parameters
#
# [*user*]
#  user running this website instance
# [*web_project_venv_path*]
#  python virtual env path of the website project
# [*web_project_path*]
#  path to the main project of the website
# [*version*]
#  preferred node version
#
# === Examples
#
#  website::nodejs { 'example.net-site1'
#    user                  => 'wwwuser',
#    web_project_venv_path => '/home/wwwuser/example.net-site1/.env',
#    web_project_path      => '/home/wwwuser/example.net-site1/example',
#    version               => '4.2.3',
#  }
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2016 Braiins Systems s.r.o.
#
define website::nodejs(
  $user,
  $web_project_venv_path,
  $web_project_path,
  $version,
) {
  $python_env_cmd = "/bin/bash -c 'source ${web_project_venv_path}/bin/activate; %s'"
  # Install prebuilt node into the python virtual env
  exec { sprintf($python_env_cmd, "nodeenv --node=${version} --prebuilt -p"):
    cwd     => $web_project_path,
    user    => $user,
    creates => "${web_project_venv_path}/bin/nodejs",
  } ->
  exec { sprintf($python_env_cmd, "npm install"):
    cwd     => $web_project_path,
    user    => $user,
  }
}
