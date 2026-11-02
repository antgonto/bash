# fraud-clf — SecMLOps course project: THE BASELINE

You have just inherited this repository. It trains a fraud classifier and serves it. It works.
It is also how most ML services look before anyone thinks about security.

Your job across the course is to take it to production-grade on your chosen platform track
(GitHub Actions, GitLab CI, or Azure DevOps) — without breaking it.

## What's here

    data/raw/train.csv   the training data (3 000 transactions)
    gen_data.py          regenerates it
    clean.py             a cleaning step
    train.py             trains and saves model/model.pkl
    src/serve.py         FastAPI: /api/health, /api/predict
    config.py            configuration
    Dockerfile, k8s/     how it is deployed today

## Run it

    pip install -r requirements.txt
    python gen_data.py && python clean.py && python train.py
    uvicorn src.serve:app --port 8080
    curl -X POST localhost:8080/api/predict -H 'content-type: application/json' \
      -d '{"instances": [[120.0, 14, 0.2, 1]]}'

## Before Lab 1.1

Read every file. List everything that worries you. Keep the list — you will check items off it
for the rest of the course, and the final milestone asks you to prove each one is closed.
