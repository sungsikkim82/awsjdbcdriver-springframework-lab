#!/bin/bash
set -e

# Load local env
ENV_FILE="$HOME/.env/awsjdbcdriver.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found. Copy .env.example and fill in values."
  exit 1
fi
source "$ENV_FILE"

# Config
APP_DIR="/root/awsjdbcdriver-lab"
JAR_NAME="awsjdbcdriver-springframework-lab-0.0.1-SNAPSHOT.jar"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 1. Building ==="
cd "$PROJECT_DIR"
./gradlew clean build -x test

echo "=== 2. Creating remote directory ==="
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "sudo mkdir -p $APP_DIR && sudo chown $EC2_USER:$EC2_USER $APP_DIR"

echo "=== 3. Uploading files ==="
scp -i "$PEM_KEY" "build/libs/$JAR_NAME" "$EC2_USER@$EC2_HOST:/tmp/$JAR_NAME"
scp -i "$PEM_KEY" "$ENV_FILE" "$EC2_USER@$EC2_HOST:/tmp/env.sh"
scp -i "$PEM_KEY" "$PROJECT_DIR/start.sh" "$EC2_USER@$EC2_HOST:/tmp/start.sh"
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "sudo mv /tmp/$JAR_NAME /tmp/env.sh /tmp/start.sh $APP_DIR/ && sudo chmod +x $APP_DIR/start.sh"

echo "=== 4. Restarting application ==="
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "sudo $APP_DIR/start.sh"

echo "=== Deploy complete ==="
echo "App: http://$EC2_HOST:8080"
