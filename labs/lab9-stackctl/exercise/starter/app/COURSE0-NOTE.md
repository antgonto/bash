# About this copy of fraud-clf

This folder is the SecMLOps program's project **exactly as students inherit it in
Course 2 Module 0** (`secmlops-project-baseline`, tag `m0`): a fraud classifier
trained by `train.py` and served by `src/serve.py` (FastAPI: `GET /api/health`,
`POST /api/predict`). Course 0 adds only `Dockerfile.course`, which trains the
model inside the image build so `stackctl` can bring the service up without a
Python toolchain on your laptop.

You will notice things in this code that should worry you — a hard-coded key pair
in `config.py`, an old `requests` pin in `requirements.txt`, no authentication on
`/api/predict`. **Do not fix them here.** They are the subject of Course 2
(Milestones 2, 4 and 10). In Course 0 you *operate* the baseline; your runbook's
"inherited findings" list is where they belong.
