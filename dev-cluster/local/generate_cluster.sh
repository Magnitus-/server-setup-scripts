#!/usr/bin/env bash

WORKER_RAM=${WORKER_RAM:-4G}
MASTER_RAM=${MASTER_RAM:-2G}
LBL_RAM=${LBL_RAM:-1G}
VM_TEMPLATE=${VM_TEMPLATE:-"k8_vm_template"}

MASTER0=$(virsh list --name --all | grep master0)

if [ -z "$MASTER0" ]; then

    for VM in $(echo "master0 master1 master2 worker0 worker1 worker2 lbl0"); do
        virt-clone --original=${VM_TEMPLATE} --name=${VM} --file=$(pwd)/disks/${VM}.qcow2;

        if [[ "$VM" =~ "master" ]]; then
            RAM=$MASTER_RAM
        elif [[ "$VM" =~ "worker" ]]; then
            RAM=$WORKER_RAM
        else
            RAM=$LBL_RAM
        fi

        virsh setmaxmem $VM $RAM --config
        virsh setmem $VM $RAM --config
    done

    ./start_cluster.sh;
    ./generate_inventory.sh;
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook set_hosts.yml -i inventory --key-file "./id_rsa";
    ./shutdown_cluster.sh;
    ./start_cluster.sh;
    ./fixate_cluster_ips.sh;
fi