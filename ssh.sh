#!/bin/bash

ssh_key_param=''
if [ ! -z "$SSH_KEY_PATH" ]; then
    ssh_key_param="-i $SSH_KEY_PATH"
fi

ssh $ssh_key_param -t -o StrictHostKeyChecking=no -o ProxyCommand="ssh $ssh_key_param -A -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -W %h:%p core@$(oc get service --all-namespaces -l run=ssh-bastion -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')" core@$1 "sudo -i"
