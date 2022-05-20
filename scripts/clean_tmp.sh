#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

TMP_PATH="../tmp"

find "$TMP_PATH/" ! -name README.md -type f -name '*' -delete
