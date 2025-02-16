#!/usr/bin/env bash

info "Scanning with trivy"
run trivy fs --no-progress "$target" 2>&1 | tee ${dist}/security_scan.txt
