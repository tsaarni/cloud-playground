# start new cluster
kind delete cluster --name cluster-trust-bundle
kind create cluster --config configs/kind-cluster-config.yaml --name cluster-trust-bundle



There was no way to access as file yet in 1.28
https://github.com/kubernetes/kubernetes/pull/113374
