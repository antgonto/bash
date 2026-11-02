"""fraud-clf serving API."""
import joblib
from fastapi import FastAPI

from config import MODEL_PATH

model = joblib.load(MODEL_PATH)          # loads whatever is in the file
app = FastAPI(title="fraud-clf")


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.post("/api/predict")
def predict(payload: dict):
    return {"probabilities": model.predict_proba(payload["instances"]).tolist()}
