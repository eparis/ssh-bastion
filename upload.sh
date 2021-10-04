#!/bin/bash

ingress_host="$(oc get service --all-namespaces -l run=ssh-bastion -o go-template='{{ with (index (index .items 0).status.loadBalancer.ingress 0) }}{{ or .hostname .ip }}{{end}}')"

scp -o ProxyCommand="ssh -A -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -W %h:%p core@${ingress_host}" $1 core@$2:.
