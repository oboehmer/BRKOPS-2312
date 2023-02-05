# BRKOPS-2312 - CiscoLive EMEA 2023

This repository contains all the examples presented during the CiscoLive 2023 Amsterdam talk
**Do’s and Don’ts in Network Test Automation** session.

In order to run them, you need a Linux, MacOS or WSL Python3 virtual environment (with `pip install -r requirements.txt`) and some IOS-XE and/or IOS-XR devices you can SSH into (configs and topology used for the session are included in the `lab/` folder in this repo). Please modify the `testbed.yaml` file to adjust IP addresses/etc. in your environment.

## RobotFramework Logfile Examples

Logfile and Report when executing all the sample tests provided:

- [Detailed HTML Log File](all-tests_logs.html)
- [Summary Report](all-tests_report.html)
- [Detailed Logs in XML](all-tests_output.xml)
