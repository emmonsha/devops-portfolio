#/usr/bin/env bash
sudo systemctl daemon-reload
sudo systemctl start emmonsha_exporter
sudo systemctl enable emmonsha_exporter 