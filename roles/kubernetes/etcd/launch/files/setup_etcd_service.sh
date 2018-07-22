#!/usr/bin/env bash

ETCD_CONTAINER=$(docker ps -a | grep k8_master_etcd)

if [ -z "$ETCD_CONTAINER" ]; then
    INITIAL_CLUSTER=""
    INDEX=$((0))

    for ELEMENT in $INVENTORY
    do
        if [ -z "$INITIAL_CLUSTER" ]; then
            INITIAL_CLUSTER="etcd${INDEX}=https://${ELEMENT}:2380"
        else
            INITIAL_CLUSTER="${INITIAL_CLUSTER},etcd${INDEX}=https://${ELEMENT}:2380"
        fi

        if [ "$ELEMENT" == "$PEER_IP" ]; then
            NAME="etcd${INDEX}"
        fi

        INDEX=$((INDEX+1))
    done

    kubeadm config images pull;
    IMAGE=$(kubeadm config images list | grep etcd)

CMD="etcd \
--name=${NAME}
--data-dir=/var/lib/etcd \
--listen-client-urls https://${PEER_IP}:2379 \
--advertise-client-urls https://${PEER_IP}:2379 \
--listen-peer-urls https://${PEER_IP}:2380 \
--initial-advertise-peer-urls https://${PEER_IP}:2380 \
--cert-file=/certs/server.pem \
--key-file=/certs/server-key.pem \
--client-cert-auth \
--trusted-ca-file=/certs/ca.pem \
--peer-cert-file=/certs/peer.pem \
--peer-key-file=/certs/peer-key.pem \
--peer-client-cert-auth \
--peer-trusted-ca-file=/certs/ca.pem \
--initial-cluster ${INITIAL_CLUSTER} \
--initial-cluster-token my-etcd-token \
--initial-cluster-state new"

    if [ "$ARCHITECTURE" = "amd64" ]; then
        docker run -d \
                   --name="k8_master_etcd" \
                   --restart=always \
                   --network=host \
                   --entrypoint="" \
                   -v /var/lib/etcd:/var/lib/etcd \
                   -v /etc/pki/etcd:/certs \
                   $IMAGE $CMD;
    else
        docker run -d \
                   --name="k8_master_etcd" \
                   --restart=always \
                   --network=host \
                   --entrypoint="" \
                   -e "ETCD_UNSUPPORTED_ARCH=arm64" \
                   -v /var/lib/etcd:/var/lib/etcd \
                   -v /etc/pki/etcd:/certs \
                   $IMAGE $CMD;
    fi
fi