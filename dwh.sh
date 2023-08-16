#!/bin/bash
# Author: retpircs
# GitHub: https://github.com/retpircs
# LICENSE: GPLv3 (https://www.gnu.org/licenses/gpl-3.0)
VERSION="1.2.3"
config_file="/etc/dwh.conf"

# Create configuration file if not available
if [ ! -f "${config_file}" ]; then
  touch "${config_file}"
  echo "#!/bin/bash" > "${config_file}"
  chmod 600 "${config_file}"
fi

# Function for checking and adding entries in the configuration file
write_config() {
  if ! grep -q "^$1=" "${config_file}"; then
    if [ -n "${3}" ]; then
      echo "${1}=\"${2}\" ${3}" >> "${config_file}"
    else
      echo "${1}=\"${2}\"" >> "${config_file}"
    fi
  fi
}

# Check and add entries to the configuration file
write_config "url" "" "# discord webhook url"
write_config "author" ""
write_config "author_url" ""
write_config "author_icon" ""
write_config "title" ""
write_config "title_url" ""
write_config "color" ""
write_config "footer" ""
write_config "footer_icon" ""
write_config "username" "" "# display name in discord"
write_config "avatar" "" "# avatar in discord"
write_config "thumbnail" ""
write_config "validate" "true" "# The script validates the arguments before sending them to avoid errors. Disabling it is not recommended."
write_config "checkupdate" "true" "# The script checks if there is a new version on GitHub and notifies the user. Disabling it is not recommended."
write_config "quiet" "false" "# no output, no matter what"

# Retrieve config
source ${config_file}
# Check if curl command is available
CURL="$(which curl)"
# Temporary file to store the downloaded content
temp_file="/tmp/dwh"
# Regular expression to match URLs
url_regex="^(http|https):\/\/[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,}){1,2}(:[0-9]+)?(\/.*)?$"
# Define download url and the version for the latest update
latest="https://raw.githubusercontent.com/retpircs/dwh/master/dwh.sh"
remote_version=$(curl -s "${latest}" | grep -o 'VERSION="[0-9.]*"' | sed 's/VERSION="//;s/"$//')

# Display usage information
usage() {
  if [ "${quiet}" != "true" ]; then
    echo "========================================="
    echo "$0 <options> <message>"
    echo ""
    echo " -h show this message"
    echo " -U <discord webhook URL> REQUIRED"
    echo ""
    echo " -a <author>"
    echo " -au <author URL> (requires author)"
    echo " -ai <author icon URL> (requires author)"
    echo ""
    echo " -t <title>"
    echo " -tu <title URL> (requires title)"
    echo " -c <color HEX> without #"
    echo ""
    echo " -f <footer>"
    echo " -fi <footer icon URL> (requires footer)"
    echo ""
    echo " -d <displayname>"
    echo " -da <avatar URL>"
    echo " -i <thumbnail URL>"
    echo ""
    echo " -s skip validations (not recommended)"
    echo " -C <config file>" overwrite default
    echo " -up update DWH (no other arguments)"
    echo " --q no output, no matter what"
    echo "Description:"
    echo " DWH sends embeds to Discord Webhooks."
    echo "Version: ${VERSION}"
    echo "========================================="
    check_update
  fi
  exit 1
}

# Display different messages with colors
error() {
  if [ "${quiet}" != "true" ]; then
    echo -e "\e[41m\e[97mERROR:\e[0m \e[31m${@}\e[0m"
  fi
  exit 1
}

warning() {
  if [ "${quiet}" != "true" ]; then
    echo -e "\e[101m\e[97mWARNING:\e[0m \e[31m${@}\e[0m"
  fi
}

info() {
  if [ "${quiet}" != "true" ]; then
    echo -e "\e[46m\e[97mINFO:\e[0m \e[93m${@}\e[0m"
  fi
}

# Check for updates, skip if checkupdate="false"
check_update() {
  if [ "${checkupdate}" != "false" ]; then
    if [ "${VERSION}" != "${remote_version}" ]; then
      info "DWH is no longer up to date. Your version: ${VERSION} | Latest version: ${remote_version}"
      info "Use '$0 -up' or check online for updates: https://github.com/retpircs/dwh"
    fi
  fi
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
        "url": "${title_url}",
        "color": ${color},
        "author": {
          "name": "${author}",
          "url": "${author_url}",
          "icon_url": "${author_icon}"
        },
        "footer": {
          "text": "${footer}",
          "icon_url": "${footer_icon}"
        },
        "thumbnail": {
          "url": "${thumbnail}"
        }
      }
    ],
    $(if [ -n "${username}" ]; then
      echo "\"username\": \"${username}\","
    fi)
    $(if [ -n "${avatar}" ]; then
      echo "\"avatar_url\": \"${avatar}\","
    fi)
    "attachments": []
  }
EOF
}

# Parse command-line options
while [ "${#}" -gt 0 ]; do
  case "${1}" in
    --q) quiet="true" ;;
    -up) sudo curl -o /bin/dwh ${latest} && chmod +x /bin/dwh && info "DWH was updated from ${VERSION} to ${remote_version}." && info "DWH path: /bin/dwh | DWH config: ${config_file}" || error "An unknown error has occurred. Download the latest version here: https://github.com/retpircs/dwh"; exit 1 ;;
    -C) config_file="${2}" && source ${config_file}; shift ;;
    -h) usage ;;
    -U) url="${2}"; shift ;;
    -a) author="${2}"; shift ;;
    -au) author_url="${2}"; shift ;;
    -ai) author_icon="${2}"; shift ;;
    -t) title="${2}"; shift ;;
    -tu) title_url="${2}"; shift ;;
    -c) color="${2}"; shift ;;
    -f) footer="${2}"; shift ;;
    -fi) footer_icon="${2}"; shift ;;
    -d) username="${2}"; shift ;;
    -da) avatar="${2}"; shift ;;
    -i) thumbnail="${2}"; shift ;;
    -s) validate="false" ;;
    *) message="${*}"; break ;;
  esac
  shift
done

# Check if there's at least one argument or a message file
if [ "${#}" -lt 1 ]; then
  usage
fi
message="${*}"

check_update

# Check if CURL is available
if [ -z "${CURL}" ]; then
    error "This script requires CURL to work."
fi

# Check if the Discord webhook URL is provided
if [ -z "${url}" ]; then
  error "The Discord webhook URL must not be empty."
fi

# Handle color parameter
if [ -n "${color}" ]; then
  if [[ "${color}" == "#"* ]]; then
    color="${color:1}"
  fi
  if [[ ${#color} -eq 6 && "${color}" =~ ^[0-9A-Fa-f]+$ ]]; then
    color=$((16#${color}))
  else
    color=null
    warning "Color must be a hex color code (without #). Using default color."
  fi
else
  color=null
fi

# Skip the validations
if [ "${validate}" != "false" ]; then

  # Perform a test request to validate the Discord webhook URL
  response="$(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST -d '{"content":null}' "${url}")"
  if [ "${response}" == "401" ]; then
    error "Invalid Webhook Token. Please check your webhook URL."
  elif [ "${response}" == "6" ]; then
    error "Could not resolve host. Please check the validity of the webhook URL."
  fi

  # Validate the author URL
  if [ -n "${author_url}" ]; then
    if [[ ! ${author_url} =~ ${url_regex} ]]; then
      author_url=""
      warning "The author URL is invalid. Removing URL to prevent discrepancies."
    fi
    if [[ -n "${author_url}" && -z "${author}" ]]; then
      author_url=""
      warning "The author URL is displayed only in connection with the author. Removing URL to prevent discrepancies."
    fi
  fi

  # Validate the author icon URL
  if [ -n "${author_icon}" ]; then
    curl -s -o "${temp_file}" "${author_icon}"
    if [[ ! -s "${temp_file}" ]]; then
      author_icon=""
      warning "The author icon URL is not reachable. Removing icon to prevent discrepancies."
    elif file -b --mime-type "${temp_file}" | grep -q -v "image/"; then
      author_icon=""
      warning "The author icon URL is available, but no image. Removing icon to prevent discrepancies."
    fi
    rm -f "${temp_file}"
    if [[ -n "${author_icon}" && -z "${author}" ]]; then
      author_icon=""
      warning "The author icon is displayed only in connection with the author. Removing icon to prevent discrepancies."
    fi
  fi

  # Validate the title URL
  if [ -n "${title_url}" ]; then
    if [[ ! ${title_url} =~ ${url_regex} ]]; then
      title_url=""
      warning "The title URL is invalid. Removing URL to prevent discrepancies."
    fi
    if [[ -n "${title_url}" && -z "${title}" ]]; then
      title_url=""
      warning "The title url is displayed only in connection with the title. Removing URL to prevent discrepancies."
    fi
  fi

  # Validate the thumbnail URL
  if [ -n "${thumbnail}" ]; then
    curl -s -o "${temp_file}" "${thumbnail}"
    if [[ ! -s "${temp_file}" ]]; then
      thumbnail=""
      warning "The thumbnail URL is not reachable. Removing thumbnail to prevent discrepancies."
    elif file -b --mime-type "${temp_file}" | grep -q -v "image/"; then
      thumbnail=""
      warning "The thumbnail URL is available, but no image. Removing thumbnail to prevent discrepancies."
    fi
    rm -f "${temp_file}"
  fi

  # Validate the footer icon URL
  if [ -n "${footer_icon}" ]; then
    curl -s -o "${temp_file}" "${footer_icon}"
    if [[ ! -s "${temp_file}" ]]; then
      footer_icon=""
      warning "The footer icon URL is not reachable. Removing icon to prevent discrepancies."
    elif file -b --mime-type "${temp_file}" | grep -q -v "image/"; then
      footer_icon=""
      warning "The footer icon URL is available, but no image. Removing icon to prevent discrepancies."
    fi
    rm -f "${temp_file}"
    if [[ -n "${footer_icon}" && -z "${footer}" ]]; then
      footer_icon=""
      warning "The footer icon is displayed only in connection with the footer. Removing icon to prevent discrepancies."
    fi
  fi

  #Validate the username
  if [ -n "${username}" ]; then
    length=${#username}
    if [ $length -lt 1 ] || [ $length -gt 80 ]; then
      username=""
      warning "The length of the display name must be between 1 and 80. Removing username to prevent discrepancies."
    fi
  fi

  # Validate the avatar URL
  if [ -n "${avatar}" ]; then
    curl -s -o "${temp_file}" "${avatar}"
    if [[ ! -s "${temp_file}" ]]; then
      avatar=""
      warning "The avatar URL is not reachable. Removing avatar to prevent discrepancies."
    elif file -b --mime-type "${temp_file}" | grep -q -v "image/"; then
      avatar=""
      warning "The avatar URL is available, but no image. Removing avatar to prevent discrepancies."
    fi
    rm -f "${temp_file}"
  fi

fi

# Send the POST request with the embed JSON
curl -H "Content-Type: application/json" -X POST -d "$(embed)" "${url}" || error "An unknown error has occurred."
