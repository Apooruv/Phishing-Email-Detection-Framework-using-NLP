#!/bin/bash

# Ensure we are in the project root
cd "$(dirname "$0")"

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo "Error: Virtual environment (venv or .venv) not found."
    exit 1
fi

# Check GPU Status
if python3 -c "import tensorflow as tf; exit(0 if len(tf.config.list_physical_devices('GPU')) > 0 else 1)" 2>/dev/null; then
    echo "GPU Acceleration: ENABLED"
else
    echo "GPU Acceleration: DISABLED (Running on CPU)"
fi

# Start the FastAPI backend in the background
echo "Starting FastAPI Backend on http://localhost:8000..."
PYTHONPATH=. uvicorn src.api.main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Start the Frontend server in the background
echo "Starting Frontend Dashboard on http://localhost:3000..."
cd frontend
python -m http.server 3000 &
FRONTEND_PID=$!

echo "----------------------------------------------------"
echo "PhishGuard is running!"
echo "Backend: http://localhost:8000"
echo "Frontend: http://localhost:3000/index.html"
echo "----------------------------------------------------"
echo "Press Ctrl+C to stop both servers."

# Handle shutdown
trap "kill $BACKEND_PID $FRONTEND_PID; exit" INT TERM EXIT

# Keep script running
wait
