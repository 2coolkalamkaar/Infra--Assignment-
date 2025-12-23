#!/bin/bash
echo "Firing requests at Nginx... Press Ctrl+C to stop."
# Loop forever
while true; do
  # 1. Hit the homepage (Success)
  curl -s -o /dev/null http://localhost:80
  
  # 2. Hit a fake page (404 Error - for graphs)
  if (( $RANDOM % 5 == 0 )); then
    curl -s -o /dev/null http://localhost:80/missing-page
  fi
  
  # 3. Hit the health endpoint
  curl -s -o /dev/null http://localhost:80/health
done
