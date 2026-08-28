import csv
import json
import boto3
from io import StringIO
from urllib.request import Request, urlopen

ECB_URL = (
    "https://data-api.ecb.europa.eu/service/data/EXR/"
    "D.USD+GBP+JPY.EUR.SP00.A"
    "?format=csvdata&lastNObservations=5"
)


def fetch_ecb_csv(opener=urlopen):
    request = Request(
        ECB_URL,
        headers={"Accept": "text/csv"},
    )

    with opener(request, timeout=10) as response:
        return response.read().decode("utf-8")

def build_document(rates, retrieved_at):
    return {
        "source": "European Central Bank",
        "base_currency": "EUR",
        "retrieved_at": retrieved_at.isoformat(),
        "rates": rates,
    }

def save_document_to_s3(
    document,
    bucket_name,
    object_key,
    s3_client=None,
):
    if s3_client is None:
        s3_client = boto3.client("s3")

    body = json.dumps(document).encode("utf-8")

    s3_client.put_object(
        Bucket=bucket_name,
        Key=object_key,
        Body=body,
        ContentType="application/json",
    )

    return object_key


def parse_latest_rates(csv_text):
    reader = csv.DictReader(StringIO(csv_text))
    latest_rates = {}

    for row in reader:
        currency = row["CURRENCY"]
        observation_date = row["TIME_PERIOD"]

        previous = latest_rates.get(currency)

        if previous is None or observation_date > previous["date"]:
            latest_rates[currency] = {
                "date": observation_date,
                "value": float(row["OBS_VALUE"]),
            }

    return latest_rates