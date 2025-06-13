# UTSA Software Capstone Design Project - Spring 2025
## EMBA GPU-Accelerated Firmware Analysis

This project enhances the [EMBA](https://github.com/e-m-b-a/emba) (Embedded Malware Binary Analyzer) tool to improve the speed and scalability of firmware analysis using GPU acceleration. Our updated module integrates seamlessly into EMBA and provides improved performance for penetration testers and security teams working with large or complex firmware.

---

## Screenshots

![VIM p51 top](https://github.com/user-attachments/assets/c82b49b2-f7f1-4298-9785-58faf650ea85)
![VIM p51 DFS GPU](https://github.com/user-attachments/assets/bf39623f-ff39-47e4-9aac-3a4c913f18d0)
![embaRunningFirmware2](https://github.com/user-attachments/assets/3d65f7df-a3dd-48a7-a976-98c0a1e09c05)

---

## Project Overview

**EMBA** is designed as the central firmware
analysis tool for penetration testers and product
security teams. It supports the complete security
analysis process starting with firmware extraction,
doing static analysis and dynamic analysis via
emulation and finally generating a web
report. EMBA automatically discovers possible
weak spots and vulnerabilities in firmware.
Examples are insecure binaries, old and outdated
software components, potentially vulnerable
scripts, or hard-coded passwords. EMBA is a
command line tool with the possibility to generate
an easy-to-use web report for further analysis.

---

## ⚙️ Objective A: GPU-Based Processing Scalability
EMBA was designed to assist in
automating, where possible, the
analytic process of evaluating one
piece of firmware at a time. The
time to process the firmware is
proportional to the complexity of
the firmware. Only one EMBA
module leverages GPU’s.


---

## Getting Started

1. **Clone the official EMBA repository**:
   ```bash
   git clone https://github.com/e-m-b-a/emba
   
2. **Replace the extraction module**:
   **Copy and overwrite module/p50_binwalk_extractor with**:
   ```bash
   module/p51_mustang_binwalk_extractor

3. Run EMBA with your updated module:
    ```bash
   ./emba.sh -f /path/to/firmware.bin

---

## Author

**Chaz Ortiz** – *Lead Developer on Group Project*  
[GitHub](https://github.com/Chaz-Ortiz) · [LinkedIn](https://www.linkedin.com/in/chaz-ortiz-615863270/) 
