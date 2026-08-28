from src.lambda_function import build_document, fetch_ecb_csv, parse_latest_rates, save_document_to_s3, run_job
from datetime import datetime, timezone
import json
import src.lambda_function as lambda_module


SAMPLE_CSV = """CURRENCY,CURRENCY_DENOM,TIME_PERIOD,OBS_VALUE
USD,EUR,2026-08-26,1.1642
GBP,EUR,2026-08-26,0.8613
USD,EUR,2026-08-27,1.1680
"""


def test_parse_latest_rates_keeps_newest_value_for_each_currency():
    result = parse_latest_rates(SAMPLE_CSV)

    assert result == {
        "USD": {
            "date": "2026-08-27",
            "value": 1.1680,
        },
        "GBP": {
            "date": "2026-08-26",
            "value": 0.8613,
        },
    }

def test_fetch_ecb_csv_downloads_text():
    class FakeResponse:
        def __enter__(self):
            return self

        def __exit__(self, exception_type, exception, traceback):
            pass

        def read(self):
            return SAMPLE_CSV.encode("utf-8")

    def fake_opener(request, timeout):
        assert request.get_header("Accept") == "text/csv"
        assert timeout == 10
        return FakeResponse()

    result = fetch_ecb_csv(opener=fake_opener)

    assert result == SAMPLE_CSV

def test_build_document_adds_metadata():
    rates = {
        "USD": {
            "date": "2026-08-28",
            "value": 1.1643,
        }
    }
    retrieved_at = datetime(
        2026, 8, 28, 12, 30, tzinfo=timezone.utc
    )

    result = build_document(rates, retrieved_at)

    assert result == {
        "source": "European Central Bank",
        "base_currency": "EUR",
        "retrieved_at": "2026-08-28T12:30:00+00:00",
        "rates": rates,
    }

def test_save_document_to_s3_sends_json():
    class FakeS3Client:
        def __init__(self):
            self.arguments = None

        def put_object(self, **arguments):
            self.arguments = arguments

    document = {
        "base_currency": "EUR",
        "rates": {"USD": {"date": "2026-08-28", "value": 1.1643}},
    }
    fake_s3 = FakeS3Client()

    result = save_document_to_s3(
        document=document,
        bucket_name="test-bucket",
        object_key="rates/2026-08-28.json",
        s3_client=fake_s3,
    )

    assert fake_s3.arguments == {
        "Bucket": "test-bucket",
        "Key": "rates/2026-08-28.json",
        "Body": json.dumps(document).encode("utf-8"),
        "ContentType": "application/json",
    }
    assert result == "rates/2026-08-28.json"

def test_run_job_combines_all_steps():
    class FakeS3Client:
        def __init__(self):
            self.arguments = None

        def put_object(self, **arguments):
            self.arguments = arguments

    fake_s3 = FakeS3Client()
    retrieved_at = datetime(
        2026, 8, 28, 12, 30, tzinfo=timezone.utc
    )

    result = run_job(
        bucket_name="test-bucket",
        retrieved_at=retrieved_at,
        fetcher=lambda: SAMPLE_CSV,
        s3_client=fake_s3,
    )

    assert result == {
        "bucket": "test-bucket",
        "key": "rates/2026/08/28/exchange-rates.json",
        "currencies": ["GBP", "USD"],
    }

    saved_document = json.loads(
        fake_s3.arguments["Body"].decode("utf-8")
    )
    assert saved_document["base_currency"] == "EUR"
    assert saved_document["rates"]["USD"]["date"] == "2026-08-27"

def test_lambda_handler_uses_bucket_environment_variable(
    monkeypatch,
):
    monkeypatch.setenv("BUCKET_NAME", "test-bucket")

    def fake_run_job(bucket_name, retrieved_at):
        assert bucket_name == "test-bucket"
        assert retrieved_at.tzinfo == timezone.utc

        return {
            "bucket": bucket_name,
            "key": "rates/test.json",
            "currencies": ["USD"],
        }

    monkeypatch.setattr(
        lambda_module,
        "run_job",
        fake_run_job,
    )

    result = lambda_module.lambda_handler({}, None)

    assert result == {
        "statusCode": 200,
        "bucket": "test-bucket",
        "key": "rates/test.json",
        "currencies": ["USD"],
    }