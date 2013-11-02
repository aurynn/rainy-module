class rainy (
    $admin_password,
    $ssl         => true,
    $ssl_cert    => "",
    $interface   => "*",
    $port        => 8080,
    $datapath    => "/var/lib/rainy/data",
    $installpath => "/opt/rainy/",
    $backend     => "sqlite",
    $version     => "0.5.0"
) {

    # Needs to be set up before most of everything 
    # else.
    $packages = ["mono-complete","libsqlite3-0", "unzip"]

    $installed = "$installpath/rainy-$version"

    package {$packages:
        ensure => present,
    }

    # Create the user
    user {"rainy":
        ensure => present
    }

    # Now,
    # Let's download the file.
    exec {"fetch rainy archive":
        command => "/usr/bin/curl http://rainy.notesync.org/release/rainy-$verision.zip > /tmp/rainy.zip",
        creates => "/tmp/rainy.zip"
    }
    exec {"unzip rainy archive":
        command => "/usr/bin/unzip",
        creates => "$installpath/rainy-$version",
        requires => [
            Package["unzip"], 
            File[$installpath]
        ]
    }

    exec {"make $datapath":
        command => "/usr/bin/mkdir -p $datapath",
        creates => "$datapath"
    }

    file {$installpath: 
        ensure => directory,
        owner  => "rainy"
    }

    file {$datapath:
        ensure => directory,
        owner => "rainy",
        require => [
            Exec["make $datapath"], 
            User["rainy"]
        ]
    }

    file {"/etc/rainy":
        ensure => directory,
        owner  => "rainy"
    }

    file {"/etc/rainy/settings.conf":
        ensure  => present,
        content => template("rainy/settings.conf.erb"),
        owner   => "rainy",
        notify  => Service["rainy"]
    }

    file {"/etc/init.d/rainy":
        ensure  => present,
        content => template("rainy/etc/init.d/rainy.erb")
    }

    file {"/var/run/rainy/":
        ensure => directory,
        owner  => "rainy"
    }
    file {"/etc/default/rainy":
        ensure => present,
        content => template("rainy/etc/default/rainy")
    }

    service {"rainy":
        ensure => running,
        require => [
            File["/etc/rainy/settings.conf"],
            File["/etc/init.d/rainy"],
            Exec["unzip rainy archive"],
            File["/var/run/rainy"],
            File["/etc/default/rainy"]
        ]
    }

    Exec["fetch rainy archive"] -> Exec["unzip rainy archive"]

}
