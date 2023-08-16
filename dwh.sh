#!/bin/bash
# Author: retpircs
# GitHub: https://github.com/retpircs
# DWH Version: 0.0.1


# Define default configuration values
url="https://discord.com/api/webhooks/1127265792463995010/ZdxOvQtLrOFJxwnmNGK4nnZ309cRTtz9nWd53X5XT8t4qJiDYvHIm09P3UpgxGa0T8HW"
title=""
author=""
icon=""
color=""

# Check if curl command is available
CURL="$(which curl)"
# Temporary file to store the downloaded content
temp_file="/tmp/dwh"

# Display usage information
usage() {
  echo "========================================="
  echo "$0 <options> <message>"
  echo ""
  echo " -h show this message"
  echo " -U <discord webhook url> \e[41m\e[97mREQUIRED\e[0m"
  echo " -t <title>"
  echo " -a <author>"
  echo " -i <icon url> only with author"
  echo " -c <color HEX> without #"
  echo " -f <footer text>"
  echo ""
  echo "Description:"
  echo " DWH sends Discord Webhook embeds."
  echo "========================================="
  exit 1
}

# Display error messages with colors
error() {
  echo -e "\e[41m\e[97mERROR:\e[0m \e[31m$@\e[0m"
  exit 1
}

warning() {
  echo -e "\e[101m\e[97mWARNING:\e[0m \e[31m$@\e[0m"
}

# Define the structure of the embed JSON
embed() {
  cat <<EOF
  {
    "content": null,
    "embeds": [
      {
        "title": "${title}",
        "description": "${message}",
        "color": ${color},
        "author": {
          "name": "${author}",
          "icon_url": "${icon}"
        },
        "footer": {
          "text": "${footer}"
        }
      }
    ],
    "attachments": []
  }
EOF
}

# Parse command-line options
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h) usage ;;
    -U) url="$2"; shift ;;
    -t) title="$2"; shift ;;
    -a) author="$2"; shift ;;
    -i) icon="$2"; shift ;;
    -c) color="$2"; shift ;;
    -f) footer="$2"; shift ;;
    *) message="$*"; break ;;
  esac
  shift
done

# Check if there's at least one argument or a message file
if [ $# -lt 1 ]; then
  usage
fi
message="$*"

# Check if CURL is available
if [ -z "${CURL}" ]; then
    error "This script requires CURL to work."
    exit 1
fi

# Check if the Discord webhook URL is provided
if [ -z "${url}" ]; then
  error "The Discord webhook URL must not be empty."
  exit 1
fi

# Perform a test request to validate the Discord webhook URL
response="$(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST -d '{"content":null}' "$url")"
if [ "$response" == "401" ]; then
  error "Invalid Webhook Token. Please check your webhook URL."
  exit 1
elif [ "$response" == "6" ]; then
  error "Could not resolve host. Please check the validity of the webhook URL."
  exit 1
fi

# Perform a test request to validate the icon URL
if [ -n "${icon}" ]; then
  curl -s -o "$temp_file" "$icon"
  if [[ ! -s "$temp_file" ]]; then
    icon=""
    warning "The icon URL is not reachable. Removing icon to prevent discrepancies."
  elif file -b --mime-type "$temp_file" | grep -q -v "image/"; then
    icon=""
    warning "The icon URL is available, but no image. Removing icon to prevent discrepancies."
  fi
  rm -f "$temp_file"

  if [[ -n "$icon" && -z "$author" ]]; then
      warning "The icon is displayed only in connection with the author."
  fi
fi

# Handle color parameter
if [ -n "$color" ]; then
  if [[ "$color" == "#"* ]]; then
    color="${color:1}"
  fi
  if [[ ${#color} -eq 6 && "$color" =~ ^[0-9A-Fa-f]+$ ]]; then
    color=$((16#${color}))
  else
    color="16711680"
    warning "Color must be a hex color code (without #). Using default color."
  fi
else
  color="null"
fi

# Send the POST request with the embed JSON
curl -H "Content-Type: application/json" -X POST -d "$(embed)" ${url} || error "An unknown error has occurred."
