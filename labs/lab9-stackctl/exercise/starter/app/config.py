"""App configuration."""
FEATURES = ["amount", "hour", "merchant_risk", "velocity_24h"]
MODEL_PATH = "model/model.pkl"
# TODO: move these somewhere safer
S3_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
S3_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
MLFLOW_URL = "http://mlflow.gonzalez.cr:5000"
