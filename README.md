# Delivery Time Data Analysis

이 저장소는 배달 시간 데이터(`delivery_time_synthetic.csv`)를 활용한 데이터 분석 머신러닝 프로젝트입니다.

## Environment

- Python: `3.11.14`
- Virtual environment: `venv`

## Setup

```bash
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Run

Jupyter Lab 실행:

```bash
source venv/bin/activate
jupyter lab
```

## Collaboration Rules

- `venv/`는 `.gitignore`에 포함되어 있으므로 커밋하지 않습니다.
- 의존성 변경 시 아래 명령으로 `requirements.txt`를 업데이트합니다.

```bash
source venv/bin/activate
pip freeze > requirements.txt
```
