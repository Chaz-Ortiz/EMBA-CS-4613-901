#!/bin/bash -p

# Chaz's Heavily modified P50, AKA P51 Mustang
# You can replace the existing P50 module with this module
# Modifications: GPU Check, Install missing dependencies, DFS Max Depth Detection, GPU acceleration, Parallelized file operations
# Interesting note: I tried to create a file with P51, but EMBA would just skip over it,
# even if I made a profile and whitelist P51 and blacklist p50 (along with the other extractors)
# so I just run this modified P50 instead

export PRE_THREAD_ENA=0

P50_binwalk_extractor() {
  module_log_init "${FUNCNAME[0]}"

# Chaz's New Dependency and GPU Check
  local GPU_AVAILABLE=0
  if command -v nvidia-smi &> /dev/null; then
    print_output "[*] NVIDIA GPU detected."
    GPU_AVAILABLE=1
  elif command -v clinfo &> /dev/null; then
    print_output "[*] OpenCL-compatible GPU detected."
    GPU_AVAILABLE=1
  fi

  # Chaz's missing dependencies Install (binwalk, parallel, findutils)
  for pkg in binwalk parallel findutils; do
    if ! command -v $pkg &> /dev/null; then
      print_output "[*] Installing missing package: $pkg"
      sudo apt-get install -y $pkg
    fi
  done

  # shellcheck disable=SC2153
  if [[ -d "${FIRMWARE_PATH}" ]] && [[ "${RTOS}" -eq 1 ]]; then
    detect_root_dir_helper "${FIRMWARE_PATH}"
  fi

  # if we have a verified UEFI firmware we do not need to do anything here
  # if we have already found a linux (RTOS==0) we do not need to do anything here
  if [[ "${UEFI_VERIFIED}" -eq 1 ]] || [[ "${RTOS}" -eq 0 ]] || [[ "${DJI_DETECTED}" -eq 1 ]] || [[ "${WINDOWS_EXE}" -eq 1 ]]; then
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  # We have seen multiple issues in system emulation while using binwalk
  # * unprintable chars in paths -> remediation in place
  # * lost symlinks in different firmware extractions -> Todo: Issue
  # * lost permissions of executables -> remediation in place
  # Currently we disable binwalk here and switch automatically to unblob is main extractor while
  # system emulation runs. If unblob fails we are going to try an additional extraction round with
  # binwalk.
  if [[ "${FULL_EMULATION}" -eq 1 ]]; then
    print_output "[-] Binwalk v3 has issues with symbolic links and is disabled for system emulation"
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  # we do not rely on any EMBA extraction mechanism -> we use the original firmware file
  local lFW_PATH_BINWALK="${FIRMWARE_PATH_BAK}"


  # Chaz's DFS-based max directory depth detection
  local MAX_DEPTH
  MAX_DEPTH=$(calculate_max_depth_dfs "${OUTPUT_DIR_BINWALK}" 1)
  print_output "[*] Maximum directory depth detected: ${MAX_DEPTH}"

  # If depth > 5, apply optimization
    if [[ "${MAX_DEPTH}" -gt 5 ]]; then
      print_output "[*] Directory depth is greater than 5. Applying optimizations for faster extraction."
      export BINWALK_OPTS="--parallel=8 --run-as=root --log=binwalk_log.txt"
    else
      export BINWALK_OPTS="--run-as=root --log=binwalk_log.txt"
    fi

    #Chaz's Binwalk call with GPU optimization if available
    if [[ -f "${lFW_PATH_BINWALK}" ]]; then
      local BINWALK_OPTS="--run-as=root --log=binwalk_log.txt"
      if [[ "${GPU_AVAILABLE}" -eq 1 ]]; then
        BINWALK_OPTS+=" --gpu"
        print_output "[*] Using GPU acceleration for Binwalk."
      fi
      binwalk -Me ${BINWALK_OPTS} "${lFW_PATH_BINWALK}" -C "${OUTPUT_DIR_BINWALK}"
    fi

    # Parallelized file operations (like processing extracted files)
    find "${OUTPUT_DIR_BINWALK}" -type f | parallel -j $(nproc) file {}

  local lFILES_BINWALK_ARR=()
  local lBINARY=""
  local lWAIT_PIDS_P99_ARR=()

  module_title "Binwalk binary firmware extractor"
  pre_module_reporter "${FUNCNAME[0]}"

  local lLINUX_PATH_COUNTER_BINWALK=0
  local lOUTPUT_DIR_BINWALK="${LOG_DIR}"/firmware/binwalk_extracted

  # Chaz's DFS-based max directory depth detection
  local MAX_DEPTH
  MAX_DEPTH=$(calculate_max_depth_dfs "${lFW_PATH_BINWALK}" 1)
  print_output "[*] Maximum directory depth detected: ${MAX_DEPTH}"

  # If depth > 5, apply optimization
  if [[ "${MAX_DEPTH}" -gt 5 ]]; then
    print_output "[*] Directory depth is greater than 5. Applying optimizations for faster extraction."
    export BINWALK_OPTS="--parallel=8 --run-as=root --log=binwalk_log.txt"
  else
    export BINWALK_OPTS="--run-as=root --log=binwalk_log.txt"
  fi 

  # Execute binwalk extraction
  if [[ -f "${lFW_PATH_BINWALK}" ]]; then
    binwalker_matryoshka "${lFW_PATH_BINWALK}" "${lOUTPUT_DIR_BINWALK}"
  fi

  # Handle extracted files and binaries
  print_ln
  if [[ -d "${lOUTPUT_DIR_BINWALK}" ]]; then
    remove_uprintable_paths "${lOUTPUT_DIR_BINWALK}"
    mapfile -t lFILES_BINWALK_ARR < <(find "${lOUTPUT_DIR_BINWALK}" -type f)
  fi

  if [[ "${#lFILES_BINWALK_ARR[@]}" -gt 0 ]]; then
    print_output "[*] Extracted ${ORANGE}${#lFILES_BINWALK_ARR[@]}${NC} files."
    print_output "[*] Populating backend data for ${ORANGE}${#lFILES_BINWALK_ARR[@]}${NC} files ... could take some time" "no_log"

    # Multithreaded extraction of binaries
    for lBINARY in "${lFILES_BINWALK_ARR[@]}" ; do
      binary_architecture_threader "${lBINARY}" "${FUNCNAME[0]}" &
      local lTMP_PID="$!"
      store_kill_pids "${lTMP_PID}"
      lWAIT_PIDS_P99_ARR+=( "${lTMP_PID}" )
    done

    lLINUX_PATH_COUNTER_BINWALK=$(linux_basic_identification "${lOUTPUT_DIR_BINWALK}" "${FUNCNAME[0]}")
    wait_for_pid "${lWAIT_PIDS_P99_ARR[@]}"

    sub_module_title "Firmware extraction details"
    print_output "[*] ${ORANGE}Binwalk${NC} results:"
    print_output "[*] Found ${ORANGE}${#lFILES_BINWALK_ARR[@]}${NC} files."
    print_output "[*] Additionally the Linux path counter is ${ORANGE}${lLINUX_PATH_COUNTER_BINWALK}${NC}."
    print_ln
    tree -sh "${lOUTPUT_DIR_BINWALK}" | tee -a "${LOG_FILE}"
  fi

  detect_root_dir_helper "${lOUTPUT_DIR_BINWALK}"

  write_csv_log "FILES Binwalk" "LINUX_PATH_COUNTER Binwalk"
  write_csv_log "${#lFILES_BINWALK_ARR[@]}" "${lLINUX_PATH_COUNTER_BINWALK}"

  module_end_log "${FUNCNAME[0]}" "${#lFILES_BINWALK_ARR[@]}"
}

# Chaz's DFS max directory depth function
calculate_max_depth_dfs() {
  local dir="$1"
  local current_depth="$2"
  local max_depth="$current_depth"

  # Loop through subdirectories
  for subdir in "$dir"/*; do
    if [[ -d "$subdir" ]]; then
      local sub_depth
      sub_depth=$(calculate_max_depth_dfs "$subdir" $((current_depth + 1)))
      if (( sub_depth > max_depth )); then
        max_depth=$sub_depth
      fi
    fi
  done

  echo "$max_depth"
}

# Chaz's Function to detect GPU acceleration availability
detect_gpu_acceleration() {
  # Check if NVIDIA CUDA is available
  if command -v nvidia-smi &>/dev/null; then
    local cuda_devices=$(nvidia-smi --list-gpus)
    if [[ -n "$cuda_devices" ]]; then
      print_output "[*] CUDA-enabled NVIDIA GPU detected."
      export CUDA_VISIBLE_DEVICES=0  # Enable the first available GPU
      print_output "[*] Enabling GPU acceleration for extraction (CUDA)."
      export GPU_ACCELERATION="CUDA"
      return
    fi
  fi

  # Chaz's Check if OpenCL is available (useful for NVIDIA, AMD, Intel GPUs)
  if command -v clinfo &>/dev/null; then
    local opencl_devices=$(clinfo | grep "OpenCL platforms")
    if [[ -n "$opencl_devices" ]]; then
      print_output "[*] OpenCL-enabled GPU detected."
      export GPU_ACCELERATION="OpenCL"
      print_output "[*] Enabling GPU acceleration for extraction (OpenCL)."
      return
    fi
  fi

  # If no GPU is detected, disable GPU acceleration
  print_output "[*] No GPU detected. Proceeding without GPU acceleration."
  export GPU_ACCELERATION="NONE"
}

linux_basic_identification() {
  local lFIRMWARE_PATH_CHECK="${1:-}"
  local lIDENTIFIER="${2:-}"
  local lLINUX_PATH_COUNTER_BINWALK=0

  if ! [[ -d "${lFIRMWARE_PATH_CHECK}" ]]; then
    return
  fi
  if [[ -n "${lIDENTIFIER}" ]]; then
    lLINUX_PATH_COUNTER_BINWALK="$(grep "${lIDENTIFIER}" "${P99_CSV_LOG}" | grep -c "/bin/\|/busybox;\|/shadow;\|/passwd;\|/sbin/\|/etc/" || true)"
  else
    lLINUX_PATH_COUNTER_BINWALK="$(grep -c "/bin/\|/busybox;\|/shadow;\|/passwd;\|/sbin/\|/etc/" "${P99_CSV_LOG}" || true)"
  fi
  echo "${lLINUX_PATH_COUNTER_BINWALK}"
}

remove_uprintable_paths() {
  local lOUTPUT_DIR_BINWALK="${1:-}"

  local lFIRMWARE_UNPRINT_FILES_ARR=()
  local lFW_FILE=""

  mapfile -t lFIRMWARE_UNPRINT_FILES_ARR < <(find "${lOUTPUT_DIR_BINWALK}" -name '*[^[:print:]]*')
  if [[ "${#lFIRMWARE_UNPRINT_FILES_ARR[@]}" -gt 0 ]]; then
    print_output "[*] Unprintable characters detected in extracted files -> cleanup started"
    for lFW_FILE in "${lFIRMWARE_UNPRINT_FILES_ARR[@]}"; do
      print_output "[*] Cleanup of ${lFW_FILE} with unprintable characters"
      print_output "[*] Moving ${lFW_FILE} to ${lFW_FILE//[![:print:]]/_}"
      mv "${lFW_FILE}" "${lFW_FILE//[![:print:]]/_}" || true
    done
  fi
}

