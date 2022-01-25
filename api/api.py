from email.policy import default
from importlib.resources import path
from tkinter import EW
from flask import Flask, make_response, request, jsonify
import os
import boto3
import json
import logging


s3_bucket = os.environ.get('S3_BUCKET')

app = Flask(__name__)

if __name__ != '__main__':
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/', methods=['GET'], defaults={'path': ''})
@app.route('/<path:path>')
def all(path):
    s3 = boto3.client('s3')
    s3_object = s3.get_object(Bucket=s3_bucket, Key=request.path[1:])
    response = make_response(s3_object['Body'].read())
    response.headers['Content-Type'] = s3_object['ContentType']
    #response.headers['Content-Disposition'] = "attachment"
    return response

if __name__ == "__main__":
    app.run(host='0.0.0.0')