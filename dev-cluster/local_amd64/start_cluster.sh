for VM in $(echo "master0 master1 master2 worker0 worker1 worker2 lbl0"); do
    virsh start $VM;
done