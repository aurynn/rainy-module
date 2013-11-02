class rainy (
    $admin_password,
    $ssl         = true,
    $ssl_cert    = "",
    $interface   = "*",
    $port        = 8080,
    $datapath    = "/var/lib/rainy/data/",
    $installpath = "/opt/rainy",
    $backend     = "sqlite",
    $version     = "0.5.0"
) {

    # Needs to be set up before most of everything 
    # else.
    $packages = ["mono-complete","libsqlite3-0", "unzip", "curl"]

    $installed = "$installpath/rainy-$version"
    $configfile = "/etc/rainy/settings.conf"
    $piddir    = "/var/run/rainy"

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
        command => "/usr/bin/curl http://rainy.notesync.org/release/rainy-$version.zip > /tmp/rainy.zip",
        creates => "/tmp/rainy.zip"
    }
    exec {"unzip rainy archive":
        command => "/usr/bin/unzip /tmp/rainy.zip -d $installpath",
        creates => "$installed/Rainy.exe",
        require => [
            Package["unzip"], 
            File[$installpath]
        ]
    }

    exec {"make $datapath":
        command => "/bin/mkdir -p $datapath",
        creates => "$datapath"
    }

    file {$installpath: 
        ensure => directory,
        owner  => "rainy"
    }
    file {$installed:
        ensure  => directory,
        owner   => "rainy",
        require => Exec["unzip rainy archive"]
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

    file {$configfile:
        ensure  => present,
        content => template("rainy/settings.conf.erb"),
        owner   => "rainy",
        notify  => Service["rainy"]
    }

    file {"/etc/init.d/rainy":
        ensure  => present,
        content => template("rainy/etc/init.d/rainy.erb"),
        mode    => "0755"
    }

    file {$piddir:
        ensure => directory,
        owner  => "rainy"
    }
    file {"$installed/rainy.sh":
        ensure  => present,
        content => template("rainy/rainy.sh.erb"),
        require => File[$installed],
        mode    => "0755"
    }
    file {"/home/rainy":
        ensure => directory,
        owner  => "rainy"
    }

    service {"rainy":
        ensure => running,
        require => [
            File[$configfile],
            File["/etc/init.d/rainy"],
            Exec["unzip rainy archive"],
            File[$piddir],
            File["$installed/rainy.sh"]
            File["/home/rainy"]
        ]
    }

    Exec["fetch rainy archive"] -> Exec["unzip rainy archive"]

}
