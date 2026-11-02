#!/usr/bin/env python3
"""Train the fraud classifier and save it."""
import joblib
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

from config import FEATURES

df = pd.read_csv("data/raw/train.csv")
clf = make_pipeline(StandardScaler(), LogisticRegression(max_iter=2000)).fit(df[FEATURES].values, df["label"].values)
joblib.dump(clf, "model/model.pkl")
print("saved model/model.pkl")
