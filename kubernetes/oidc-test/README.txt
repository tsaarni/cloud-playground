

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










http -v --verify /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://kubernetes.default.svc/.well-known/openid-configuration Authorization:"Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
GET /.well-known/openid-configuration HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Authorization: Bearer <service account token>
Connection: keep-alive
Host: kubernetes.default.svc
User-Agent: HTTPie/3.2.4



HTTP/1.1 200 OK
Audit-Id: 68570cb1-cb9b-44b6-9ab4-34db35079986
Cache-Control: public, max-age=3600
Content-Length: 236
Content-Type: application/json
Date: Mon, 13 Oct 2025 14:48:55 GMT
X-Kubernetes-Pf-Flowschema-Uid: 6008f2cd-f4b8-46a2-92a6-6066e97de5e6
X-Kubernetes-Pf-Prioritylevel-Uid: 52917ccc-ff31-4a90-8719-46b323ca9642

{
    "id_token_signing_alg_values_supported": [
        "RS256"
    ],
    "issuer": "https://kubernetes.default.svc.cluster.local",
    "jwks_uri": "https://172.20.0.2:6443/openid/v1/jwks",
    "response_types_supported": [
        "id_token"
    ],
    "subject_types_supported": [
        "public"
    ]
}


http -v --verify /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://172.20.0.2:6443/openid/v1/jwks Authorization:"Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
GET /openid/v1/jwks HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Authorization: Bearer <service account token>
Connection: keep-alive
Host: 172.20.0.2:6443
User-Agent: HTTPie/3.2.4



HTTP/1.1 200 OK
Audit-Id: 853ca185-7e79-48d9-9f13-1ae3ad639c28
Cache-Control: public, max-age=3600
Content-Length: 462
Content-Type: application/jwk-set+json
Date: Mon, 13 Oct 2025 15:02:50 GMT
X-Kubernetes-Pf-Flowschema-Uid: 6008f2cd-f4b8-46a2-92a6-6066e97de5e6
X-Kubernetes-Pf-Prioritylevel-Uid: 52917ccc-ff31-4a90-8719-46b323ca9642

{
    "keys": [
        {
            "alg": "RS256",
            "e": "AQAB",
            "kid": "<kid>",
            "kty": "RSA",
            "n": "<n>",
            "use": "sig"
        }
    ]
}



### Without Authorization header

http -v --verify /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://172.20.0.2:6443/openid/v1/jwks
GET /openid/v1/jwks HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: 172.20.0.2:6443
User-Agent: HTTPie/3.2.4



HTTP/1.1 403 Forbidden
Audit-Id: ff365055-1c9b-4c1e-a096-bd6903c0a5c4
Cache-Control: no-cache, private
Content-Length: 199
Content-Type: application/json
Date: Mon, 13 Oct 2025 15:03:54 GMT
X-Content-Type-Options: nosniff
X-Kubernetes-Pf-Flowschema-Uid: 41647404-5314-431f-ad8f-569626bc2484
X-Kubernetes-Pf-Prioritylevel-Uid: b23247de-eee6-4678-b4ee-b04904b7e2e8

{
    "apiVersion": "v1",
    "code": 403,
    "details": {},
    "kind": "Status",
    "message": "forbidden: User \"system:anonymous\" cannot get path \"/openid/v1/jwks\"",
    "metadata": {},
    "reason": "Forbidden",
    "status": "Failure"
}



## Allow unauthenticated access to discovery and JWKS endpoint

kubectl create clusterrolebinding oidc-reviewer  \
   --clusterrole=system:service-account-issuer-discovery \
   --group=system:unauthenticated




