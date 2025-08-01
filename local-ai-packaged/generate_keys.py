
import base64
import hashlib
import hmac
import json
import sys

def b64_encode(data):
    return base64.urlsafe_b64encode(data).replace(b'=', b'')

def generate_jwt(payload, secret):
    header = {"alg": "HS256", "typ": "JWT"}
    
    encoded_header = b64_encode(json.dumps(header, separators=(",", ":")).encode())
    encoded_payload = b64_encode(json.dumps(payload, separators=(",", ":")).encode())
    
    signature_input = b"%s.%s" % (encoded_header, encoded_payload)
    
    signature = hmac.new(secret.encode(), signature_input, hashlib.sha256).digest()
    encoded_signature = b64_encode(signature)
    
    return b"%s.%s.%s" % (encoded_header, encoded_payload, encoded_signature)

if __name__ == "__main__":
    secret = "6c3d861e1f98b209a343138404b1c673fd8a9657842e568b8cb188680d8d16b4"
    
    anon_payload = {"role": "anon"}
    service_role_payload = {"role": "service_role"}
    
    anon_key = generate_jwt(anon_payload, secret)
    service_role_key = generate_jwt(service_role_payload, secret)
    
    print("ANON_KEY=" + anon_key.decode())
    print("SERVICE_ROLE_KEY=" + service_role_key.decode())
