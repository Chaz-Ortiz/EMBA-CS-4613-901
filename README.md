# UTSA Software Capstone Design Project - Spring 2025

## EMBA - Firmware security analysis

P51 Mustang binwalk extractor is a module for [EMBA](https://github.com/e-m-b-a/emba) (Embedded Malware Binary Analyzer) to improve the speed and scalability of firmware analysis by performing a depth-first traversal of the file system, using GPU acceleration, and parallelization of file operations. My updated module integrates into the existing EMBA software and provides improved performance for penetration testers and security teams working with large or complex firmware.

## Objective: GPU-Based Processing Scalability
EMBA was designed to assist in
automating, where possible, the
analytic process of evaluating one
piece of firmware at a time. The
time to process the firmware is
proportional to the complexity of
the firmware. Only one EMBA
module leverages GPU’s.

## Screenshots

![VIM p51 top](https://github.com/user-attachments/assets/c82b49b2-f7f1-4298-9785-58faf650ea85)
![VIM p51 DFS GPU](https://github.com/user-attachments/assets/bf39623f-ff39-47e4-9aac-3a4c913f18d0)
![embaRunningFirmware2](https://github.com/user-attachments/assets/3d65f7df-a3dd-48a7-a976-98c0a1e09c05)

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

## Author

**Chaz Ortiz** – *Lead Developer on Group Project*  
[GitHub](https://github.com/Chaz-Ortiz) · [LinkedIn](https://www.linkedin.com/in/chaz-ortiz-615863270/) 
