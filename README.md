VirtualBox Service Tool
=======================

This tool creates service definitions for [runit] so it can manage your headless [VirtualBox] VMs.

It generates 'control' scripts so runit will use `VBoxManage` to gracefully stop or kill the VMs, and can also generate a 'check' script for use with `sv start`.

Usage
-----

In this example, we will create services to manage two virtual machines:

*   `pfSense`, a gateway that routes the internet to a host-only network. It has the static IP address `172.32.0.1` which will be used to determine its liveness.
*   `Workspace`, a development server that connects using the host-only network. 

We first create the service for the `pfSense` VM, placing it outside of the runit 'service' directory:

	create-virtualbox-service.sh /usr/local/var/svc.d/pfsense pfSense 172.32.0.1

The service is created with a `down` file, so you can expose it to runit right away:
	
	cd /usr/local/var/service
	ln -s ../svc.d/pfsense

The second virtual machine does not have a static IP, so we omit that when creating the service:

	create-virtualbox-service.sh /usr/local/var/svc.d/workspace Workspace

The `run` script can be edited to require that the `pfSense` VM is online before it starts:

	#!/bin/sh
	exec 2>&1
	sv start pfsense && exec /usr/bin/VBoxHeadless --startvm Workspace --vrde off

Finally, we expose the `workspace` service to runit and start both VMs:

	cd /usr/local/var/service
	ln -s ../svc.d/workspace
	sv up workspace

License
-------
This code is dedicated to the Public Domain as per the [Creative Commons CC0 1.0 Universal declaration][CC0].

Contributing
------------
Pull requests are welcome. If you want me to merge your changes, please include a statement that you are the original author of the changes and are dedicating them to the Public Domain.

[runit]: http://smarden.org/runit/
[VirtualBox]: https://www.virtualbox.org/
[CC0]: http://creativecommons.org/publicdomain/zero/1.0/
