#!/bin/bash
# Dedicated to the Public Domain as per the CC0 1.0 Universal declaration at
# http://creativecommons.org/publicdomain/zero/1.0/

set -e

this="$(basename $0)"

function print_usage {
	cat 1>&2 <<EOF
Usage: ${this} service_path uuid_or_name [ip]

The service is created at the service_path with a 'down' file in place.
The uuid_or_name can be found using 'VBoxManage list vms'.
If specified, the ip is used to generate a 'check' script.

Example: ${this} /usr/local/var/svc.d/vm-pfsense pfSense 172.16.0.1
EOF
	exit 1
}

function get_tool {
	tool="$(which ${1})"
	if [ -x "${tool}" ]
	then
		echo "${tool}"
	else
		echo "Could not find ${1}" 1>&2
		exit 1
	fi
}

path_VBoxHeadless="$(get_tool VBoxHeadless)"
path_VBoxManage="$(get_tool VBoxManage)"
path_sh="$(get_tool sh)"
path_svlogd="$(get_tool svlogd)"
path_ping="$(get_tool ping)"

service_path="$1"
[[ -n "${service_path}" ]] || print_usage
uuid="$2"
[[ -n "${uuid}" ]] || print_usage
ip="$3"

echo "Creating a service to control ${uuid}"
echo -n "at ${service_path}... "
mkdir -p ${service_path}
cd ${service_path}
touch down

mkdir -p log
pushd log > /dev/null
mkdir -p main
cat > run <<EOF
#!${path_sh}
exec ${path_svlogd} -tt main
EOF
chmod +x run
popd > /dev/null

mkdir -p control
pushd control > /dev/null
cat > t <<EOF
#!${path_sh}
exec 2>&1
exec ${path_VBoxManage} controlvm ${uuid} acpipowerbutton
EOF
chmod +x t
cat > k <<EOF
#!${path_sh}
exec 2>&1
exec ${path_VBoxManage} controlvm ${uuid} poweroff
EOF
chmod +x k
popd > /dev/null

cat > run <<EOF
#!${path_sh}
exec 2>&1
exec ${path_VBoxHeadless} --startvm ${uuid} --vrde off
EOF
chmod +x run

echo "Done."

if [ -n "${ip}" ]
then
echo -n "Generating a 'check' script that pings ${ip}... "
cat > check <<EOF
#!${path_sh}
exec >/dev/null 2>&1
exec ${path_ping} -q -c 1 ${ip}
EOF
chmod +x check
echo "Done."
fi
