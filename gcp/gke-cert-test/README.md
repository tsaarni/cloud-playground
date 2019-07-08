

    export GCP_PROJECT=$(gcloud config get-value project)
    gcloud config set compute/zone <GCP_REGION>

    # create kubernetes cluster with pre-emptible VMs
    gcloud container clusters create mycluster --preemptible --num-nodes=2

    # enable istio
    gcloud beta container clusters update mycluster --update-addons=Istio=ENABLED --istio-config=auth=MTLS_STRICT

    # check that cluster is up and running
    kubectl get nodes


    # build container image for httpbin
    gcloud builds submit --tag gcr.io/${GCP_PROJECT}/httpbin:1 docker/httpbin

    # deploy httpbin
    kubectl httpbin.yaml

    # find out the ip address of the ingress gateway
    kubectl get services --all-namespaces

    # allocate that address as static IP
    gcloud compute addresses create kube --addresses=<STATIC_IP_ADDRESS> --region=<GCP_REGION>

    # add the IP address to DNS
    gcloud dns record-sets transaction start --zone <DNS_ZONE_NAME>
    gcloud dns record-sets transaction add "<STATIC_IP_ADDRESS>" --name kube.example.com. --ttl 30 --type A --zone <DNS_ZONE_NAME>
    gcloud dns record-sets transaction execute --zone <DNS_ZONE_NAME>

    # create service account to update DNS record (for ACME challenge)
    #     https://github.com/stefanprodan/istio-gke/blob/master/docs/istio/05-letsencrypt-setup.md
    gcloud iam service-accounts create dns-admin \
      --display-name=dns-admin \
      --project=${GCP_PROJECT}

    gcloud iam service-accounts keys create ./gcp-dns-admin.json \
      --iam-account=dns-admin@${GCP_PROJECT}.iam.gserviceaccount.com \
      --project=${GCP_PROJECT}

    gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
      --member=serviceAccount:dns-admin@${GCP_PROJECT}.iam.gserviceaccount.com \
      --role=roles/dns.admin

    # store service account credentials to secret
    kubectl create secret generic cert-manager-credentials \
      --from-file=./gcp-dns-admin.json \
      --namespace=istio-system


    # install jetstack cert-manager
    #     https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html
    kubectl create namespace cert-manager
    kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.8.1/cert-manager.yaml

    kubectl apply -f certificates.yaml
    # wait for certificate to be issued....

    # make request using https
    http https://kube.example.com/headers
