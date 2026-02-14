from flask import Flask, make_response, request, jsonify, send_from_directory
import os
import boto3
import logging
from botocore.exceptions import ClientError, NoCredentialsError

# Get bucket name from environment variable
S3_BUCKET = os.environ.get('S3_BUCKET')

# Validate bucket configuration at startup
if not S3_BUCKET:
    raise RuntimeError("S3_BUCKET environment variable is required")

# Define app name
app = Flask(__name__)

# Use Gunicorn logger
if __name__ != '__main__':
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)
else:
    logging.basicConfig(level=logging.INFO)

# Initialize S3 client once (singleton pattern)
_s3_client = None


def get_s3_client():
    """Get or create S3 client singleton."""
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client('s3')
    return _s3_client


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(
        os.path.join(app.root_path, 'static'),
        'favicon.ico',
        mimetype='image/vnd.microsoft.icon'
    )


@app.route('/health')
def health():
    """Health check endpoint for Kubernetes probes."""
    try:
        s3 = get_s3_client()
        s3.head_bucket(Bucket=S3_BUCKET)
        app.logger.debug(f"Health check passed for bucket: {S3_BUCKET}")
        return jsonify({"status": "healthy"}), 200
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        app.logger.error(f"Health check failed: {error_code}")
        return jsonify({
            "status": "error",
            "description": f"S3 bucket access failed: {error_code}"
        }), 503
    except NoCredentialsError:
        app.logger.error("Health check failed: No AWS credentials")
        return jsonify({
            "status": "error",
            "description": "AWS credentials not configured"
        }), 503


@app.route('/', methods=['GET'], defaults={'path': ''})
@app.route('/<path:path>')
def get_object(path):
    """Retrieve object from S3 bucket and return it."""
    s3_key = request.path.lstrip('/')

    if not s3_key:
        return jsonify({
            "status": "error",
            "description": "No object key specified"
        }), 400

    try:
        s3 = get_s3_client()
        s3_object = s3.get_object(Bucket=S3_BUCKET, Key=s3_key)

        response = make_response(s3_object['Body'].read())
        response.headers['Content-Type'] = s3_object.get('ContentType', 'application/octet-stream')

        if 'ContentLength' in s3_object:
            response.headers['Content-Length'] = s3_object['ContentLength']

        app.logger.debug(f"Successfully served: {s3_key}")
        return response

    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')

        if error_code == 'NoSuchKey':
            app.logger.warning(f"Object not found: {s3_key}")
            return jsonify({
                "status": "error",
                "description": "Object not found"
            }), 404
        elif error_code == 'AccessDenied':
            app.logger.error(f"Access denied for object: {s3_key}")
            return jsonify({
                "status": "error",
                "description": "Access denied"
            }), 403
        else:
            app.logger.error(f"S3 error for {s3_key}: {error_code}")
            return jsonify({
                "status": "error",
                "description": f"S3 error: {error_code}"
            }), 500

    except NoCredentialsError:
        app.logger.error("AWS credentials not configured")
        return jsonify({
            "status": "error",
            "description": "Server configuration error"
        }), 500


if __name__ == "__main__":
    app.run(host='127.0.0.1', debug=True)
