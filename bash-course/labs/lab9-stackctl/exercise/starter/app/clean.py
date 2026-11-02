#!/usr/bin/env python3
"""DVC stage `clean`: drop nulls/duplicates, remove non-positive amounts, write data/clean/train.csv."""
import os

import pandas as pd

df = pd.read_csv("data/raw/train.csv").dropna().drop_duplicates()
df = df[df.amount > 0]
os.makedirs("data/clean", exist_ok=True)
df.to_csv("data/clean/train.csv", index=False)
print(f"clean: {len(df)} rows")
