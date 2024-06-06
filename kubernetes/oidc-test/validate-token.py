import requests
import json
from authlib.jose import jwt

TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"
CA_CERT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
OIDC_DISCOVERY_URL = "https://kubernetes.default.svc/.well-known/openid-configuration"

def get_service_account_token():
    with open(TOKEN_PATH, 'r') as token_file:
        return token_file.read().strip()

def get_kubernetes_public_keys():
    # Use the pod's default service account token to authenticate with the Kubernetes API.
    token = get_service_account_token()
    headers = {
        "Authorization": f"Bearer {token}",
    }

    print(f"Fetching OIDC discovery endpoint from {OIDC_DISCOVERY_URL}...")
    response = requests.get(OIDC_DISCOVERY_URL, verify=CA_CERT_PATH, headers=headers)
    response.raise_for_status()

    openid_discovery = response.json()
    jwks_uri = openid_discovery['jwks_uri']

    print(f"Fetching public keys from {jwks_uri}...")
    response = requests.get(jwks_uri, verify=CA_CERT_PATH, headers=headers)
    response.raise_for_status()

    return response.json()

def validate_token(token, public_keys):
    claims = jwt.decode(token, public_keys)
    claims.validate()
    return claims

def main():
    public_keys = get_kubernetes_public_keys()

    print("Validating the default service account token in the pod...")
    token = get_service_account_token()

    claims = validate_token(token, public_keys)
    if claims:
        print("Token is valid!")
        print("Claims:", json.dumps(claims, indent=4))
    else:
        print("Token is invalid!")

if __name__ == "__main__":
    main()
