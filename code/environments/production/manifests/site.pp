class base {
  class { 'ntp':
    servers => ['0.uk.pool.ntp.org','1.uk.pool.ntp.org','2.uk.pool.ntp.org'],
  }

  $searchdomain = 'puplab.local'
  $nameservers = ['192.168.8.220']

  file { '/etc/resolv.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('resolver/resolv.conf.erb'),
  }

  group { 'admins':
    ensure => present,
    gid => '500',
  }

  user { 'markh':
    ensure           => 'present',
    gid              => '500',
    home             => '/home/markh',
    groups	     => ['sudo','admins','adm'],
    password         => '$1$KPLyqk/x$SlQoKHK7hRO/PCfcciCoP/',
    password_max_age => '99999',
    password_min_age => '0',
    shell            => '/bin/bash',
    uid              => '1000',
    purge_ssh_keys   => true,
  }

  ssh_authorized_key { 'nick@magpie.example.com':
    ensure => present,
    user   => 'markh',
    type   => 'ssh-rsa',
    key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCn2jATFIkqEj9bfeEVj6g1Q2D88x3oudeF/g4Cba9AVyF1E6mJEaOLSJdYVnuH491Se32sylAOtFGz3VKoLbZ1YMEwwW4BF+7EUXdWVSL1S9UNtWkWW5XfGEmYH+3Yf+1gzRzRJfZvZLVl78qOShqkPqV05LVFO7sd6X11FovrFFODmivwM17ruB8cZkbBVvWhokUq5vUqhHDdHlRqxPikaXZS7aob5F2vrR/OMWCnd5zQlpMmV84AjUW44YqO1Wk9vVYKpz8cx5yaKak6y6J4RkBN73XDIaeY+/ulrkV5shqjvXshdVOMGf7CdpbpHDXSIYzop/EyMh8YG0wIKuAx',
  }

  class { 'sudo': }
  sudo::conf { 'admins':
    priority => 30,
    content  => "admins ALL=(ALL) ALL",
  }

}


node default {

  ## You can just use "include base" here, but this allows us to pass parameters if we ever expand it
  class {base: }

}

## Any node with "web" in it's name:
node /.*web.*/ {

  @@haproxy::balancermember { $::fqdn:
    listening_service => 'puppet00',
    server_names      => $::hostname,
    ipaddresses       => $::ipaddress,
    ports             => '80',
    options           => 'check',
  }


  ## You can just use "include base" here, but this allows us to pass parameters if we ever expand it
  class {base: }

  include nginx

}

node /.*lb.*/ {

  class {base: }

  class { 'haproxy': }
  haproxy::listen { 'puppet00':
    ipaddress => $::ipaddress,
    ports     => '80',
    mode      => 'http',
  }

  haproxy::balancermember { 'haproxy':
  listening_service => 'puppet00',
  ports             => '80',
  server_names      => ['mcweb01', 'mcweb02'],
  ipaddresses       => ['192.168.8.225', '192.168.8.226'],
  options           => 'check',
  }


}

