FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY predict_server.py .
COPY retrain.py .
COPY db.py .
COPY model.cbm .
COPY stats.json .
COPY mock_data_3.csv .

EXPOSE 5050

CMD ["python", "predict_server.py"]
