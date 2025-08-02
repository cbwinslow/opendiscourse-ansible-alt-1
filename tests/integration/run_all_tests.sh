#!/bin/bash
set -e
cd "$(dirname "$0")"
for test in *.yml; do
  echo "Running $test..."
  ansible-playbook $test || echo "$test FAILED"
done
