#!/bin/bash

ssh -t -o StrictHostKeyChecking=no -o ProxyCommand='ssh -A -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -W %h:%p core@$(oc get service -n ssh-bastion ssh-bastion -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")' core@$1 "sudo -i"
