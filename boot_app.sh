#!/bin/bash
cd /app
exec rackup -o 0.0.0.0 -p 80 >>/var/log/app.log 2>&1
