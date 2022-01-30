from flask import Flask, make_response, request, jsonify, send_from_directory
import os
import boto3
import json
import logging

# Get bucket name from environment variable
s3_bucket = os.environ.get('S3_BUCKET')

# Define app name
app = Flask(__name__)

# Use Gunicorn logger
if __name__ != '__main__':
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                          'favicon.ico',mimetype='image/vnd.microsoft.icon')

# Health check. K8S will use it to check the status of the pod
@app.route('/health')
def health():
    # Bucket not defined
    if s3_bucket is not None:
        # Test if we can access the bucket
        s3 = boto3.client('s3')
        s3_object = s3.head_bucket(Bucket=s3_bucket)
        print(s3_object)
        return json.dumps(s3_object)
    else:
        return jsonify({
            "status":"error",
            "description": "bucket not defined"
        }) , 500
        

# Catch-all route. Process all the requests.
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
    app.run(host='127.0.0.1')