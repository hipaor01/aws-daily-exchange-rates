from src.lambda_function import parse_latest_rates


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