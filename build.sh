#!/usr/bin/env bash
set -euo pipefail

red='\n\e[1;31m%s\e[0m\n'
green='\n\e[;32m%s\e[0m\n'

env=""
platform="all"

while getopts ":e:p:" opt; do
  case ${opt} in
    e) env="$OPTARG" ;;
    p) platform="$OPTARG" ;;
    \?) printf "$red" "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

if [[ -z "$env" ]]; then
  printf "$red" "Environment must be set: ./build.sh -e staging|production [-p android|ios|all]"
  exit 1
fi

if [[ ! -f "lib/env/${env}/.env" ]]; then
  printf "$red" "No env file at lib/env/${env}/.env"
  exit 1
fi

printf "$green" "Environment now: $env"
cp -a "lib/env/${env}/.env" .env

fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs

printf "$green" "Platform now: $platform"

if [[ "$platform" == "android" || "$platform" == "all" ]]; then
  fvm flutter build apk --release
  printf "$green" "Flutter build Android DONE"
fi

if [[ "$platform" == "ios" || "$platform" == "all" ]]; then
  fvm flutter build ipa --release
  printf "$green" "Flutter build iOS DONE"
fi
