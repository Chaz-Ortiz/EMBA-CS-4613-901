#!/bin/bash -p

# EMBA - EMBEDDED LINUX ANALYZER
# Optimized Version of: S10_binaries_basic_check
# Goal: Improve speed by minimizing subprocesses, using regex efficiently, and enabling parallelism.

S10_binaries_basic_check_performance() {
  module_log_init "${FUNCNAME[0]}"
  module_title "Check binaries for critical functions (Optimized)"
  pre_module_reporter "${FUNCNAME[0]}"

  local lBIN_COUNT=0
  local lVULNERABLE_FUNCTIONS=""
  local lCOUNTER=0
  local TMP_RESULT_FILE
  TMP_RESULT_FILE=$(mktemp)

  # Load list of known insecure/vulnerable functions from config
  lVULNERABLE_FUNCTIONS="$(config_list "${CONFIG_DIR}/functions.cfg")"

  if [[ "${lVULNERABLE_FUNCTIONS}" == "C_N_F" ]]; then
    print_output "[!] Config not found"
    return
  elif [[ -z "${lVULNERABLE_FUNCTIONS}" ]]; then
    print_output "[!] No vulnerable functions specified in config"
    return
  fi

  # Display all interesting functions to the user
  print_output "[*] Interesting functions: $(echo "${lVULNERABLE_FUNCTIONS}" | paste -sd' ' -)\\n"

  # Build a single regex for grep -E (faster than -e per line)
  local VUL_FUNC_REGEX
  VUL_FUNC_REGEX="$(echo "${lVULNERABLE_FUNCTIONS}" | paste -sd'|' -)"

  # Extract list of binaries from P99 CSV
  mapfile -t BINARIES < <(grep ";ELF" "${P99_CSV_LOG}" | cut -d ';' -f2 | sort -u || true)
  lBIN_COUNT=${#BINARIES[@]}

  if [[ $lBIN_COUNT -eq 0 ]]; then
    print_output "[-] No binaries found for analysis"
    module_end_log "${FUNCNAME[0]}" "0"
    return
  fi

  # Process each binary in parallel using xargs -P (limited to number of cores)
  printf "%s\n" "${BINARIES[@]}" | xargs -P "$(nproc)" -I {} bash -c '
    BINARY="{}"
    RESULT=$(readelf -s --use-dynamic "${BINARY}" 2>/dev/null | grep -E "'"${VUL_FUNC_REGEX}"'" | grep -v "file format" || true)
    if [[ -n "${RESULT}" ]]; then
      echo "::FOUND:::${BINARY}" >> "'"${TMP_RESULT_FILE}"'"
      echo "::DATA:::${RESULT}" >> "'"${TMP_RESULT_FILE}"'"
    fi
  '

  # Process results
  if grep -q "::FOUND:::" "${TMP_RESULT_FILE}"; then
    local CURRENT_BINARY=""
    while IFS= read -r LINE; do
      if [[ "${LINE}" == "::FOUND:::"* ]]; then
        CURRENT_BINARY="${LINE#::FOUND:::}"
        print_ln
        print_output "[+] Interesting function in $(print_path "${CURRENT_BINARY}") found:"
        ((lCOUNTER++))
      elif [[ "${LINE}" == "::DATA:::"* ]]; then
        local FUNC_LINE="${LINE#::DATA:::}"
        FUNC_LINE="$(echo "${FUNC_LINE}" | sed -e 's/[[:space:]]\+/\t/g')"  # Normalize whitespace
        print_output "$(indent "${FUNC_LINE}")"
      fi
    done < "${TMP_RESULT_FILE}"
  fi

  print_ln
  print_output "[*] Found ${ORANGE}${lCOUNTER}${NC} binaries with interesting functions in ${ORANGE}${lBIN_COUNT}${NC} files"
  rm -f "${TMP_RESULT_FILE}"

  module_end_log "${FUNCNAME[0]}" "${lCOUNTER}"
}