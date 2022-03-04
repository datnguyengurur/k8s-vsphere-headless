#!/bin/bash
DEBIAN_FRONTEND=noninteractive
sudo apt install haproxy keepalived -y;
readarray -t masterips < /tmp/masterips
## get length of $distro array
len=${#masterips[@]}
INTERNAL_IP=$(ip addr show ens192 | grep "inet " | awk '{print $2}' | cut -d / -f 1);

## Use bash for loop 
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg 
frontend kubernetes
    bind 0.0.0.0:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
EOF
for (( i=0; i<$len; i++ )); 
do echo "    server master-$i ${masterips[$i]}:6443 check fall 3 rise 2" | sudo tee -a /etc/haproxy/haproxy.cfg; 
done

SELF=$(hostname -s)
if [[ $SELF = "dev-lb-1" ]]
then
role=MASTER
prio=200
else
prio=100
role=BACKUP
fi

cat << EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance $(hostname -s) {
    state $role
    interface ens192
    virtual_router_id 100
    priority $prio
    authentication {
        auth_type PASS
        auth_pass $hapass
    }
    virtual_ipaddress {
        $vip
    }
}
EOF

sudo systemctl restart keepalived;
sudo systemctl restart haproxy;