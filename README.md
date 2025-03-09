# Spring 2025 - UTSA Software Capstone Design Program Project

EMBA is designed as the central firmware
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

## Objective A: Processing scalability speed with GPU’s
EMBA was designed to assist in
automating, where possible, the
analytic process of evaluating one
piece of firmware at a time. The
time to process the firmware is
proportional to the complexity of
the firmware. Only one EMBA
module leverages GPU’s.
