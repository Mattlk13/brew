# Helpers for Homebrew's executables.txt database.

# HOMEBREW_CACHE is set by utils/ruby.sh
# HOMEBREW_LIBRARY is set by bin/brew
# HOMEBREW_API_DEFAULT_DOMAIN HOMEBREW_API_DOMAIN HOMEBREW_CURL HOMEBREW_CURLRC
# HOMEBREW_CURL_SPEED_LIMIT HOMEBREW_CURL_SPEED_TIME HOMEBREW_USER_AGENT_CURL are set by brew.sh
# shellcheck disable=SC2153,SC2154
source "${HOMEBREW_LIBRARY}/Homebrew/utils/api.sh"
source "${HOMEBREW_LIBRARY}/Homebrew/utils.sh"

HOMEBREW_EXECUTABLES_TXT_ENDPOINT="internal/executables.txt"

executables_txt_cache_file() {
  echo "${HOMEBREW_CACHE}/api/${HOMEBREW_EXECUTABLES_TXT_ENDPOINT}"
}

download_and_cache_executables_file() {
  local database_file
  database_file="$(executables_txt_cache_file)"

  if [[ -s "${database_file}" ]]
  then
    [[ -z "${HOMEBREW_SKIP_UPDATE}" ]] || return

    local -a stat_printf
    if [[ -n "${HOMEBREW_MACOS}" ]]
    then
      stat_printf=("/usr/bin/stat" "-f")
    else
      stat_printf=("/usr/bin/stat" "-c")
    fi

    local file_mtime
    local current_time
    local auto_update_secs
    file_mtime="$("${stat_printf[@]}" %m "${database_file}")"
    current_time=$(date +%s)
    auto_update_secs=${HOMEBREW_API_AUTO_UPDATE_SECS:-450}

    [[ $((current_time - auto_update_secs)) -ge ${file_mtime} ]] || return
  fi

  mkdir -p "${database_file%/*}"
  ohai "Downloading executables.txt"

  local arg
  local -a curl_disable_curlrc_args
  while read -r arg
  do
    curl_disable_curlrc_args+=("${arg}")
  done < <(api_curlrc_args)

  local -a time_cond=()
  while read -r arg
  do
    time_cond+=("${arg}")
  done < <(api_time_cond_args "${database_file}")

  local curl_exit_code url
  # Keep curl request handling in sync with `fetch_api_file` in
  # Library/Homebrew/cmd/update.sh.
  while read -r url
  do
    ${HOMEBREW_CURL} \
      "${curl_disable_curlrc_args[@]}" \
      --fail --compressed --silent \
      --speed-limit "${HOMEBREW_CURL_SPEED_LIMIT}" --speed-time "${HOMEBREW_CURL_SPEED_TIME}" \
      --location --remote-time --output "${database_file}" \
      "${time_cond[@]}" \
      --user-agent "${HOMEBREW_USER_AGENT_CURL}" \
      "${url}"
    curl_exit_code=$?
    [[ ${curl_exit_code} -eq 0 ]] && break
  done < <(api_urls "${HOMEBREW_EXECUTABLES_TXT_ENDPOINT}")

  [[ ${curl_exit_code} -eq 0 ]] || return "${curl_exit_code}"

  touch "${database_file}"

  git config --file="${HOMEBREW_REPOSITORY}/.git/config" --bool homebrew.commandnotfound true 2>/dev/null
}

formulae_containing_executable() {
  local executable="$1"
  local formula cmds_text

  while IFS=':' read -r formula cmds_text
  do
    [[ -z "${formula}" ]] && continue
    [[ -z "${cmds_text}" ]] && continue

    # `executables.txt` lines are `formula(version):exe exe...`. Keep the
    # executable list as one string for whole-word matching below.
    # Padding both sides with spaces avoids matching `foo` inside `foobar`.
    if [[ " ${cmds_text} " == *" ${executable} "* ]]
    then
      echo "${formula%\(*}"
    fi
  done <"$(executables_txt_cache_file)" 2>/dev/null
}
