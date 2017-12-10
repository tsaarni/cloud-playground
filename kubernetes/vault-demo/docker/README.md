

Run following if building on minikube

    eval $(minikube docker-env)


To build the containers by running following commands

    docker build -t vault:0.9.0 vault
    docker build -t client:1.0.0 client
