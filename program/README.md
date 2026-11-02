# program/ — the SecMLOps program's own scripts, as inherited

Read-only copies of real scripts from Course 1 (`secmlops-infra`) and Course 2
(`secmlops-pipelines`, the milestone repositories, the project baseline), shipped so
that Course 0 can read them line by line. They are **not run** in this course (they
need the lab, the CI platforms and the scanners); do not edit them.

| File | From | Read in |
| --- | --- | --- |
| `ci/sarif_gate.sh` | Course 2 Lab 13.2 | M05 S05.6, M08 S08.5 |
| `ci/validate_unauth.sh` | Course 2 Chapter 11 | M05 S05.6, M06 S06.6, M07, M08 S08.5 |
| `ci/deploy.sh`, `ci/versions.env` | Course 2 Lesson 9.1 (deploy.sh as finished at the last milestone) | M05, M06 S06.6, M09 S09.3 |
| `ci/so_upload.sh` | Course 2 Chapter 13 | M04, M05 S05.6 |
| `scripts/replica-check.sh` | Course 1 Part C | M06 S06.6, M07 |
| `scripts/ready-check.sh` | Course 2 Module 0 (project baseline) | M00, M02, M04 |
| `Makefile` | Course 1 (`secmlops-infra`) — the lab's `make up` / `make smoke` / `make ready` menu | M04 (reading) |

`fixtures/` holds **course-authored** sample files in the shapes those scripts read
(a SARIF 2.1.0 report, a SecObserve-style JSON list, and `attestation.json`, a
DSSE-style envelope whose `payload` is a base64 in-toto statement — the shape
`cosign verify-attestation` prints in Course 2 Chapter 8; its signature field is a
placeholder, not a real signature). They are not real scanner
output; the counts in them are the ones the course pages quote.
