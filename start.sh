#!/bin/bash
APP_DIR="/root/awsjdbcdriver-lab"
JAR_NAME="awsjdbcdriver-springframework-lab-0.0.1-SNAPSHOT.jar"

# Stop existing process
pkill -f "$JAR_NAME" || true
sleep 3

# Start application with env vars
source "$APP_DIR/env.sh"
nohup java -jar "$APP_DIR/$JAR_NAME" > "$APP_DIR/app.log" 2>&1 &
echo "Started. PID: $!"
