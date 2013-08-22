#!/bin/bash
# vim: nu ai aw
set -e

data_if=eth1
data_vlan=914
data_ip=172.16.202.200/23
gw_ip=172.16.202.1


function install_pkg(){
	apt-get install -y $@
}

function ensure_command(){
	cmd=$1
	pkg=$2

	if ! which $cmd > /dev/null; then
		install_pkg $2
	fi

	which $cmd > /dev/null
}

function kvm_check(){
	ensure_command kvm-ok cpu-checker
}

function network_check(){
	ifconfig eth0 > /dev/null

	ensure_command vconfig vlan
	modprobe 8021q
	
	if ! ifconfig $data_if.$data_vlan > /dev/null; then
		vconfig add $data_if $data_vlan
		ifconfig $data_if.$data_vlan > /dev/null
	fi

	ifconfig $data_if.$data_vlan $data_ip up

	ping -c 3 -I $data_if.$data_vlan $gw_ip
}

function cleanup() {
	vconfig rem $data_if.$data_vlan
	ifconfig $data_if 0

	apt-get purge -y vlan
	rmmod 8021q
}

kvm_check
network_check
cleanup

