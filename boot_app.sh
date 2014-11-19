#!/bin/sh
cd /app
exec rackup >>/var/log/app.log 2>&1
