

Run following if building on minikube

    eval $(minikube docker-env)


To build the container run following command

    docker build -t vault:0.9.0 .


To test the image run following:

    docker run --rm -it --cap-add IPC_LOCK --name vault vault:0.9.0 vault server --dev

    docker exec -it vault ash
    export VAULT_ADDR='http://127.0.0.1:8200'
    vault mount pki
    vault write pki/root/generate/internal common_name="my app root CA"
