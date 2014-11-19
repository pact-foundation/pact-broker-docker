#!/bin/bash
VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port8080,tcp,,8080,,8080";
