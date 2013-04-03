2414n.rb
=====

Commandline interface to Insteon devices via SmartLinc 2414N

**Usage**:

    ./2414n.rb <device> <command> <level> [<options>]

**Options**:

* `device` hardware address
* `command` is  `on`, `faston`, `off`, `fastoff`, or `status`, defaults to `status`
*  `level` brightness level `0 - 100`, optional
*  `-c <controller>` address of Insteon SmartLinc 2414N
*  `-u <username>` http username, optional
*  `-p <password>` http password, optional
*  `-n` create a new config file at ~/.2414n.yaml

**Examples**:

Get status of lights.  Options and device address stored in ~/.2414n.yaml

    ./2414n.rb lights

Turn device 00.9A.EF on to 50% using controller at 192.168.1.2 with authentication

    ./2414n.rb -c 192.168.1.2 -u admin -p password 009AEF faston 50
