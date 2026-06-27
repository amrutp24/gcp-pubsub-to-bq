import os
import base64
import json
import logging
from flask import Flask, request
from google.cloud import bigquery

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

BQ_PROJECT = os.environ["BQ_PROJECT"]
BQ_DATASET = os.environ["BQ_DATASET"]
BQ_TABLE = os.environ["BQ_TABLE"]

bq_client = bigquery.Client(project=BQ_PROJECT)
table_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TABLE}"


@app.route("/", methods=["POST"])
def handle_pubsub():
    envelope = request.get_json(silent=True)
    if not envelope or "message" not in envelope:
        logging.error("Invalid Pub/Sub envelope: %s", envelope)
        return "Bad Request: missing Pub/Sub message", 400

    message = envelope["message"]
    raw = base64.b64decode(message.get("data", "")).decode("utf-8")

    try:
        payload = json.loads(raw)
        if not isinstance(payload, dict):
            payload = {"value": payload}
    except (json.JSONDecodeError, ValueError):
        payload = {"raw_data": raw}

    row = {
        "message_id": message.get("messageId"),
        "publish_time": message.get("publishTime"),
        "data": raw,
        "attributes": json.dumps(message.get("attributes") or {}),
    }

    errors = bq_client.insert_rows_json(table_ref, [row])
    if errors:
        logging.error("BigQuery insert errors: %s", errors)
        return f"BigQuery insert failed: {errors}", 500

    logging.info("Inserted message %s into %s", message.get("messageId"), table_ref)
    return "OK", 200


@app.route("/health", methods=["GET"])
def health():
    return "OK", 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
