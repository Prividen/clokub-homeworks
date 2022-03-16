#! /usr/bin/env python3
import hvac
import os
from flask import Flask, request
from flask_restful import Resource, Api

def err_exit(err_msg):
    raise SystemExit(f"Error: {err_msg}")

try:
    vault_addr = os.environ["VAULT_ADDR"]
except KeyError:
    err_exit("Required VAULT_ADDR environment")

try:
    vault_token = os.environ["VAULT_TOKEN"]
except KeyError:
    err_exit("Required VAULT_TOKEN environment")

vault_client = hvac.Client(
    url=vault_addr,
    token=vault_token
)

if not vault_client.is_authenticated():
    err_exit("Error vault login")


app = Flask(__name__)
api = Api(app)

class Info(Resource):
    def get(self):
        obtained_secret = vault_client.secrets.kv.v2.read_secret_version(
            path='netology',
        )['data']['data']['secret']
        return {'netology_secret': obtained_secret}

api.add_resource(Info, '/get_secret')

if __name__ == '__main__':
     app.run(host='0.0.0.0', port='8080')
