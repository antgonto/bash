#!/usr/bin/env python3
"""Generate the synthetic card-transaction dataset used throughout the SecMLOps labs.

Deterministic (seeded) so every student gets byte-identical data and DVC hashes.
Columns: amount, hour (0-23), merchant_risk (0-1), velocity_24h, label (1 = fraud).
"""
import argparse

import numpy as np
import pandas as pd


def make(n: int, seed: int = 42, fraud_rate: float = 0.12) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    label = (rng.random(n) < fraud_rate).astype(int)
    amount = np.where(label == 1, rng.lognormal(6.0, 0.9, n), rng.lognormal(3.8, 0.8, n)).round(2)
    hour = np.where(label == 1, rng.choice(24, n, p=_night_heavy()), rng.integers(0, 24, n))
    merchant_risk = np.clip(np.where(label == 1, rng.beta(5, 2, n), rng.beta(2, 5, n)), 0, 1).round(3)
    velocity_24h = np.where(label == 1, rng.poisson(6, n), rng.poisson(1.5, n))
    df = pd.DataFrame({"amount": amount, "hour": hour, "merchant_risk": merchant_risk,
                       "velocity_24h": velocity_24h, "label": label})
    return df.sample(frac=1, random_state=seed).reset_index(drop=True)


def _night_heavy():
    p = np.ones(24)
    p[0:6] *= 4
    return p / p.sum()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--rows", type=int, default=3000)
    ap.add_argument("--out", default="data/raw/train.csv")
    ap.add_argument("--poison", action="store_true", help="inject bad rows + label flips (Lab 3.1)")
    a = ap.parse_args()
    df = make(a.rows)
    if a.poison:
        bad = pd.DataFrame({"amount": [999_999.0, 250_000.0], "hour": [3, 99], "merchant_risk": [0.5, 1.7],
                            "velocity_24h": [2, -4], "label": [1, 0]})
        df = pd.concat([df, bad], ignore_index=True)
        flip = df.sample(frac=0.45, random_state=1).index
        df.loc[flip, "label"] = 1
        print("POISONED: out-of-range rows + label flips injected")
    df.to_csv(a.out, index=False)
    print(f"wrote {len(df)} rows to {a.out} (fraud rate {df.label.mean():.3f})")
