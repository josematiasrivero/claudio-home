#!/bin/bash
cd "$(dirname "$0")"
docker compose down 2>/dev/null
docker compose up -d --build
