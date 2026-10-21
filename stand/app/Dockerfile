FROM python:3.12-slim

WORKDIR /app
RUN pip install --no-cache-dir psycopg[binary]

CMD ["python", "sqli_demo.py", "safe", "test"]