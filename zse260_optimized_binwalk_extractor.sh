export PRE_THREAD_ENA=0

P50_binwalk_extractor() {
  module_log_init "${FUNCNAME[0]}"

  if [[ -d "${FIRMWARE_PATH}" ]] && [[ "${RTOS}" -eq 1 ]]; then
    detect_root_dir_helper "${FIRMWARE_PATH}"
  fi

  if [[ "${UEFI_VERIFIED}" -eq 1 ]] || [[ "${RTOS}" -eq 0 ]] || [[ "${DJI_DETECTED}" -eq 1 ]] || [[ "${WINDOWS_EXE}" -eq 1 ]]; then
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  local lFW_PATH_BINWALK="${FIRMWARE_PATH_BAK}"

  if [[ -d "${lFW_PATH_BINWALK}" ]]; then
    print_output "[-] Binwalk module only handles firmware files."
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  module_title "Optimized Binwalk Firmware Extractor"
  pre_module_reporter "${FUNCNAME[0]}"

  export OUTPUT_DIR_BINWALK="${LOG_DIR}/firmware/binwalk_extracted"

  # Determine max depth using efficient find command
  local MAX_DEPTH=$(find "${OUTPUT_DIR_BINWALK}" -type d | awk -F'/' '{print NF}' | sort -n | tail -1)
  print_output "[*] Maximum directory depth detected: ${MAX_DEPTH}"

  # Detect GPU availability
  local GPU_AVAILABLE=0
  if command -v nvidia-smi &> /dev/null; then
    print_output "[*] NVIDIA GPU detected."
    GPU_AVAILABLE=1
  elif command -v clinfo &> /dev/null; then
    print_output "[*] OpenCL-compatible GPU detected."
    GPU_AVAILABLE=1
  fi

  # Install missing dependencies
  for pkg in binwalk parallel findutils; do
    if ! command -v $pkg &> /dev/null; then
      print_output "[*] Installing missing package: $pkg"
      sudo apt-get install -y $pkg
    fi
  done

  # Binwalk execution strategy
  local BINWALK_OPTS="--run-as=root --log=binwalk_log.txt"
  if [[ "${MAX_DEPTH}" -ge 10 ]] && [[ "${GPU_AVAILABLE}" -eq 1 ]]; then
    BINWALK_OPTS+=" --gpu"
    print_output "[*] Using GPU acceleration."
  fi

  if [[ -f "${lFW_PATH_BINWALK}" ]]; then
    binwalk -Me ${BINWALK_OPTS} "${lFW_PATH_BINWALK}" -C "${OUTPUT_DIR_BINWALK}"
  fi

  # Parallelized file operations
  find "${OUTPUT_DIR_BINWALK}" -type f | parallel -j $(nproc) file {}

  detect_root_dir_helper "${OUTPUT_DIR_BINWALK}"
  module_end_log "${FUNCNAME[0]}" "$(find "${OUTPUT_DIR_BINWALK}" -type f | wc -l)"
}
