FROM python:3.11-slim
RUN apt-get update && apt-get install -y jq curl && rm -rf /var/lib/apt/lists/*
ENV PYTHONUNBUFFERED=1
WORKDIR /app
RUN pip install --no-cache-dir flask
COPY . .
RUN chmod +x cprice.sh
CMD ["python", "app.py"]
