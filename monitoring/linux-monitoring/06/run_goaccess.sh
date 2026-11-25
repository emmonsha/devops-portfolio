#!/usr/bin/env bash

sudo goaccess -f ../04/access*.log -o /var/www/html/index.html \
  --log-format=COMBINED \
  --real-time-html \
  --port=7890 
