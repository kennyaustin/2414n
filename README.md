2414n.rb
=====

Commandline interface to Insteon devices via SmartLinc 2414N

**Usage**:

    ./2414n.rb <controller> <device> <command> <level> [<options>]

**Options**:

* `controller` address of Insteon SmartLinc 2414N
* `device` hardware address
* `command` is  `on`, `faston`, `off`, `fastoff`, or `status`, defaults to `status`
*  `level` brightness level `0 - 100`, optional
*  `-u <username>` http username, optional
*  `-p <password>` http password, optional

**Examples**:

Get status of device 00.9A.EF via 2414N controller at 192.168.1.2

    ./2414n.rb 192.168.1.2 009AEF 

Turn device 00.9A.EF to 50%

    ./2414n.rb 192.168.1.2 009AEF faston 50

Turn device 00.9A.EF off using authentication

    ./2414n.rb 192.168.1.2 009AEF fastoff -u admin -p password

