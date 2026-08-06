#!/usr/bin/env bash
set -euo pipefail

fvm flutter clean
fvm dart run build_runner clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
