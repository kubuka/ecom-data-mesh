from dotenv import load_dotenv
import os
from requests import get
from datetime import datetime
import pandas as pd
import sys

api_key = os.getenv("EX_API_KEY")
url = f"http://api.currencylayer.com/live?access_key={api_key}&source=USD"

response = get(url)
response.raise_for_status()

data = response.json()
kurs = data["quotes"]
dt_format = datetime.fromtimestamp(data["timestamp"])
timestamp = datetime.strftime(dt_format, "%Y-%m-%d")
tabular_data = []

for key, value in kurs.items():
    key = key[3:]
    tabular_data.append({"currency": key, "rate": value, "date": timestamp})

# final_ex_rate = {"timestamp": timestamp, "kurs": clean_up_kurs}
data_str = datetime.strftime(dt_format, "%Y%m%d")
df = pd.DataFrame(tabular_data)
df.to_csv(
    f"/opt/data/exchange_rate/fresh_exchange_rate_{data_str}.csv",
    index=False,
    sep=",",
    encoding="utf-8",
)
# with open(
#     f"../data/exchange_rate/fresh_exchange_rate_{data_str}.json",
#     "w",
#     encoding="utf-8",
# ) as f:
#     json.dump(final_ex_rate, f, indent=4)
