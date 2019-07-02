#!/bin/bash

ssh -t -o StrictHostKeyChecking=no -o ProxyCommand='ssh -A -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -W %h:%p core@$(oc get service --all-namespaces -l run=ssh-bastion -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}")' core@$1 "sudo -i"
