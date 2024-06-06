

kind create cluster

kubectl apply -f manifests/shell.yaml

kubectl cp validate-token.py shell:.
kubectl exec shell -- python validate-token.py



###

python3 -mvenv .venv
. .venv/bin/activate



### Test output

Fetching OIDC discovery endpoint from https://kubernetes.default.svc/.well-known/openid-configuration...
Fetching public keys from https://172.20.0.3:6443/openid/v1/jwks...
Validating the default service account token in the pod...
Token is valid!
Claims: {
    "aud": [
        "https://kubernetes.default.svc.cluster.local"
    ],
    "exp": 1749183792,
    "iat": 1717647792,
    "iss": "https://kubernetes.default.svc.cluster.local",
    "jti": "358fa733-fa25-4e06-a337-03f67c021c00",
    "kubernetes.io": {
        "namespace": "default",
        "node": {
            "name": "contour-worker",
            "uid": "517eb86e-b863-451b-bf70-86cb61439a3a"
        },
        "pod": {
            "name": "shell",
            "uid": "0d8b260e-ef0e-45fb-be8e-ff44f97722e8"
        },
        "serviceaccount": {
            "name": "default",
            "uid": "e6a8680e-d103-4cce-80ea-03acbbeacf7d"
        },
        "warnafter": 1717651399
    },
    "nbf": 1717647792,
    "sub": "system:serviceaccount:default:default"
}
