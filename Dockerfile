FROM python:3.12-slim

# Python environment best practices
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    NLTK_DATA=/usr/share/nltk_data

WORKDIR /app

# Install system build dependencies, install requirements, and cleanup in one layer
COPY requirements.txt .
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get purge -y --auto-remove build-essential \
    && rm -rf /var/lib/apt/lists/*

# --- Caching Optimization: Setup NLTK before copying the whole codebase ---
COPY src/utils/setup_nltk.py ./src/utils/
RUN mkdir -p /usr/share/nltk_data && \
    python src/utils/setup_nltk.py

# Copy the rest of the application
COPY . .

# --- Security: Use a non-root user ---
RUN useradd -m appuser && \
    chown -R appuser:appuser /app && \
    chown -R appuser:appuser /usr/share/nltk_data

USER appuser

EXPOSE 8000

CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
