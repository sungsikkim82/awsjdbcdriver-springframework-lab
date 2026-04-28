#!/bin/bash
set -e

# Config
EC2_HOST="<ec2-public-dns>"
EC2_USER="ec2-user"
PEM_KEY="<path-to-pem-key>"
APP_DIR="/root/awsjdbcdriver-lab"
JAR_NAME="awsjdbcdriver-springframework-lab-0.0.1-SNAPSHOT.jar"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 1. Building ==="
cd "$PROJECT_DIR"
./gradlew clean build -x test

echo "=== 2. Creating remote directory ==="
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "sudo mkdir -p $APP_DIR && sudo chown $EC2_USER:$EC2_USER $APP_DIR"

echo "=== 3. Uploading jar ==="
scp -i "$PEM_KEY" "build/libs/$JAR_NAME" "$EC2_USER@$EC2_HOST:/tmp/$JAR_NAME"
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "sudo mv /tmp/$JAR_NAME $APP_DIR/"

echo "=== 4. Restarting application ==="
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" << EOF
  # Stop existing process
  sudo pkill -f "$JAR_NAME" || true
  sleep 3

  # Start application
  sudo bash -c "nohup java -jar $APP_DIR/$JAR_NAME > $APP_DIR/app.log 2>&1 &"
  echo "Started."
EOF

echo "=== Deploy complete ==="
echo "App: http://$EC2_HOST:8080"
