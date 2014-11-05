group { "puppet":
   ensure => "present",
}

exec { "apt-update":
    command => "/usr/bin/apt-get update",
}

Exec["apt-update"] -> Package <| |>

exec { "Setup" :
	command => "/vagrant_data/setup.sh Replica1",
}

