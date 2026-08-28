import csv
from io import StringIO


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