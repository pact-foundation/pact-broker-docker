#!/bin/bash
cd /app
exec rackup -p 80 >>/var/log/app.log 2>&1
