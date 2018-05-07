# Clair vulnerability scanner

Install helm

    kubectl create serviceaccount tiller --namespace kube-system
    kubectl apply -f manifests/helm-rbac.yaml
    helm init --service-account tiller

Get Clair repository and install it

    git clone https://github.com/coreos/clair.git
    cd clair/contrib/helm
    helm dependency update clair
    helm install clair 

Launch container in order to use Clair

    kubectl run --rm -it --image=alpine alpine ash

Within container, install python and git

    apk add -U python py-pip git
    git clone https://github.com/yfoelling/yair.git
    cd yair
    pip install -r requirements.txt
