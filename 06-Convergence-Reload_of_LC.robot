*** Settings ***
# !!!!  Run the jobfile like this:
#           robot jobfiles/asr9010/1.5_Resiliency_and_HA/2.5.4.1_Reload_of_LC.robot

Metadata    Version     1.0
Metadata    Author      Solution Validation Services Cisco

# Add your project variables yaml file here or include it within your project resource file
#Variables   ${EXECDIR}/data/common.yaml

# Add your project keyword resource file, which in turn refers to required CX baseline repos
Resource    ${EXECDIR}/resources/project.resource

Test Setup       baseline setup with checks for selected devices  devices=${DUT_1}
Test Teardown    baseline teardown with checks for selected devices  devices=${DUT_1}

*** Variables ***
# !!! Update these variable accordingly
${TEST_ID}      2.5.4.1
${TEXT_REPORT_TITLE}      Reload of A9K-24X10GE-1G-SE Linecard
${TEXT_REPORT_DESCRIPTION}      Reload a Line Card element from CLI and record any impact on traffic.

#Specify the target device
${DUT_1}      R3-PASPE3

#Speciy the target linecard and its expected state in 'show platform' output
${DUT_1_LC_LOCATION}      0/2/CPU0
${DUT_1_LC}      A9K-24X10GE-1G-SE
${DUT_1_LC_EXPECTED_STATE}      IOS XR RUN

#Filter any traffic items that are expected to fail (blackhole) in the ixia analysis step
@{TRAFFIC_FILTER_PORT}      6:22  6:26
&{TRAFFIC_FILTER_SOURCE}      ixia_heading=Tx Port  match_string=${TRAFFIC_FILTER_PORT}  match_type=not in
&{TRAFFIC_FILTER_DEST}      ixia_heading=Rx Port  match_string=${TRAFFIC_FILTER_PORT}  match_type=not in
@{TRAFFIC_FILTERS}      ${TRAFFIC_FILTER_SOURCE}  ${TRAFFIC_FILTER_DEST}

# Update the list of commands you would like to capture before and after the event.
# The parsed outputs of these commands will be captured and compared to record any differences.
@{command_list}      show platform
...               show inventory
...               show route summary
...               show isis adjacency
...               show mpls ldp neighbor brief
...               show bgp vpnv4 unicast summary
...               show bgp vpnv6 unicast summary
...               show mpls traffic-eng tunnels brief
...               show bundle brief

${SLEEP_TIME_AFTER_DOWN_EVENT}      60
${SLEEP_TIME_AFTER_UP_EVENT}      120
${MAX_TIME_TO_WAIT_FOR_UP_EVENT}      900

*** Test Cases ***
Reload of A9K-24X10GE-1G-SE Linecard
    [Tags]    DUT=${DUT_1}    Test_type=Resilience    Disruptive=Yes    Traffic=Yes    Platform=IOSXR    Technology=SP    Test_ID=${TEST_ID}
    clear snmp and syslog logs
    Step 1 - Start Ixia traffic and confirm no traffic drops
    Step 2 - Check status before down event
    Step 3 - Down event
    Step 4 - Check status after down event and before up event
    Step 5 - Get traffic stats from Ixia after down event
    Step 6 - Reset traffic statistics and confirm no traffic drops
    Step 7 - Up event
    Step 8 - Check status after up event
    Step 9 - Get traffic stats from Ixia after up event
    Step 10 - Reset traffic statistics and confirm no traffic drops
    Compare parsed outputs from before down event (step 2) and after down event (step 4)
    Compare parsed outputs from before down event (step 2) and after up event (step 8)


*** Keywords ***
set variables for updating cxtm result fields
    # These are used to populate the result fields on CXTM
    ${CXTM_RESULT_SUMMARY_IF_PASS}=  catenate  SEPARATOR=\n
    ...  <p>Automated baseline checks passed, which shows the topology meets the defined baseline.</p>
    ...  <p>LC Reload event completed successfully and it booted back in state '${DUT_1_LC_EXPECTED_STATE}' after ${LC_RELOAD_TIME} seconds. All blackholed flows recovered successfully within ${LC_RELOAD_TIME} + ${TRAFFIC_RECOVERY_TIME} seconds after initiating the reload.</p>
    #...  <p>LC Reload event completed successfully and it booted back in state '${DUT_1_LC_EXPECTED_STATE}' after ${LC_RELOAD_TIME} seconds. Furthermore, no traffic flows were blackholed.</p>
    ...  <p>Traffic convergence times from down and up events for the various traffic profiles. Acceptable traffic loss duration: ${ACCEPTABLE_LOSS} msec</p>
    ...  <p>- Down Event: ${DOWN_LOSS} msec</p>
    #...  <p>- Down Event: NA (as all traffic flows were blackholed)</p>
    ...  <p>- Up Event: ${UP_LOSS} msec</p>
    #...  <p>- Up Event: NA (as all traffic flows were blackholed)</p>
    ...  <p>All blackholed flows were excluded from analysis for the entire duration of reload.</p>
    Set Suite Variable  ${CXTM_RESULT_SUMMARY_IF_PASS}

Step 1 - Start Ixia traffic and confirm no traffic drops
    ixia connect and start selected traffic items  IXIA_TRAFFIC_ITEMS=${IXIA_BASELINE_TRAFFIC_ITEMS}
    ${flows}=  ixia save flow stats  filename=${TEST_ID}_Traffic_01_Before_Down_Event
    ixia analyse verify all flows are under given packet loss duration value  flows=${flows}  value=${BASELINE_LOSS}  event=Traffic_01_Before_Down_Event


Step 2 - Check status before down event
    ${status}=  Run Keyword And Return Status  Variable Should Exist  ${DUT_CONNECTION}
    IF  ${status}
      disconnect from device "${DUT_1}"
      connect to device "${DUT_1}" via "${DUT_CONNECTION}"
    ELSE
      connect to device "${DUT_1}"
    END
    ${dut_1_lc_inventory_location}=  Get Regexp Matches  ${DUT_1_LC_LOCATION}  \\d+\/\\d+
    Set Test Variable  ${dut_1_lc_inventory_location}
    iosxr verify inventory contains module  name=${dut_1_lc_inventory_location}[0]  pid=${DUT_1_LC}
    iosxr verify module is in state  module=${DUT_1_LC_LOCATION}  expected_state=${DUT_1_LC_EXPECTED_STATE}
    ${DUT_1_parsed_1}=  iosxr get parsed output from list of commands  command_list=${command_list}
    Set Test Variable  ${DUT_1_parsed_1}


Step 3 - Down event
    utility set test comment  Down event: 'reload location ${DUT_1_LC_LOCATION}' on device '${DUT_1}'
    select device "${DUT_1}"
    sendline "reload location ${DUT_1_LC_LOCATION}"
    run "y"
    ${DOWN_EVENT_TIMESTAMP}=  Get Current Date
    Set Test Variable  ${DOWN_EVENT_TIMESTAMP}
    utility set test comment  Sleep ${SLEEP_TIME_AFTER_DOWN_EVENT} seconds
    sleep  ${SLEEP_TIME_AFTER_DOWN_EVENT}


Step 4 - Check status after down event and before up event
    select device "${DUT_1}"
    #iosxr verify inventory does not contain module  name=${dut_1_lc_inventory_location}[0]
    #iosxr verify module is not in state  module=${DUT_1_LC_LOCATION}  expected_state=${DUT_1_LC_EXPECTED_STATE}
    iosxr verify module is not present  module=${DUT_1_LC_LOCATION}

    ${DUT_1_parsed_2}=  iosxr get parsed output from list of commands  command_list=${command_list}
    Set Test Variable  ${DUT_1_parsed_2}


Step 5 - Get traffic stats from Ixia after down event
    ${flows}=  ixia save flow stats  filename=${TEST_ID}_Traffic_02_After_Down_Event
    #utility set test comment  For this particular case, all traffic flows are blackholed upon LC failure, so no analysis is performed for traffic loss.
    ${DOWN_LOSS}=  ixia analyse verify selected flows are under given packet loss duration value  flows=${flows}  value=${ACCEPTABLE_LOSS}  event=Traffic_02_After_Down_Event  warn_only=${TRUE}  filter_name=Traffic with alternate path  filters=${TRAFFIC_FILTERS}
    #${DOWN_LOSS}=  ixia analyse verify all flows are under given packet loss duration value  flows=${flows}  value=${ACCEPTABLE_LOSS}  event=Traffic_02_After_Down_Event  warn_only=${TRUE}
    Set Test Variable  ${DOWN_LOSS}


Step 6 - Reset traffic statistics and confirm no traffic drops
    ${TRAFFIC_STATS_RESET_TIMESTAMP}=  Get Current Date
    Set Test Variable  ${TRAFFIC_STATS_RESET_TIMESTAMP}
    ixia clear statistics
    utility set test comment  Sleep 20 seconds
    sleep  20
    ${flows}=  ixia save flow stats  filename=${TEST_ID}_Traffic_03_Before_Up_Event
    ixia analyse verify selected flows are under given packet loss duration value  flows=${flows}  value=${BASELINE_LOSS}  event=Traffic_03_Before_Up_Event  warn_only=${TRUE}  filter_name=Traffic with alternate path  filters=${TRAFFIC_FILTERS}
    #ixia analyse verify all flows are under given packet loss duration value  flows=${flows}  value=${BASELINE_LOSS}  event=Traffic_03_Before_Up_Event  warn_only=${TRUE}


Step 7 - Up event
    utility set test comment  Up event: Waiting for LC '${DUT_1_LC_LOCATION}' on device '${DUT_1}' to be in state '${DUT_1_LC_EXPECTED_STATE}'
    select device "${DUT_1}"
    ${status}  ${LC_RELOAD_TIME}=  iosxr wait for module to be in expected state  module=${DUT_1_LC_LOCATION}  expected_state=${DUT_1_LC_EXPECTED_STATE}  max_time_to_wait=${MAX_TIME_TO_WAIT_FOR_UP_EVENT}  from_time=${DOWN_EVENT_TIMESTAMP}
    Set Test Variable  ${LC_RELOAD_TIME}
    ${UP_EVENT_TIMESTAMP}=  Get Current Date
    Set Test Variable  ${UP_EVENT_TIMESTAMP}
    utility set test comment  Sleep ${SLEEP_TIME_AFTER_UP_EVENT} seconds
    sleep  ${SLEEP_TIME_AFTER_UP_EVENT}


Step 8 - Check status after up event
    select device "${DUT_1}"
    iosxr verify inventory contains module  name=${dut_1_lc_inventory_location}[0]  pid=${DUT_1_LC}
    iosxr verify module is in state  module=${DUT_1_LC_LOCATION}  expected_state=${DUT_1_LC_EXPECTED_STATE}
    utility set test title  Get parsed outputs of various show commands on device '${DUT_1}' after up event, for comparison use later in the test
    ${DUT_1_parsed_3}=  iosxr get parsed output from list of commands  command_list=${command_list}
    Set Test Variable  ${DUT_1_parsed_3}


Step 9 - Get traffic stats from Ixia after up event
    ${flows}=  ixia save flow stats  filename=${TEST_ID}_Traffic_04_After_Up_Event
    #utility set test comment  For this particular case, all traffic flows were blackholed upon LC failure, so no analysis is performed for traffic loss.
    ${UP_LOSS}=  ixia analyse verify selected flows are under given packet loss duration value  flows=${flows}  value=${ACCEPTABLE_LOSS}  event=Traffic_04_After_Up_Event  warn_only=${TRUE}  filter_name=Traffic with alternate path  filters=${TRAFFIC_FILTERS}
    #${UP_LOSS}=  ixia analyse verify all flows are under given packet loss duration value  flows=${flows}  value=${ACCEPTABLE_LOSS}  event=Traffic_04_After_Up_Event  warn_only=${TRUE}
    Set Test Variable  ${UP_LOSS}


Step 10 - Reset traffic statistics and confirm no traffic drops
    ${status}  ${TRAFFIC_BLACKHOLE_DURATION}=  ixia wait for traffic to be lossless  value=${BASELINE_LOSS}  max_time_to_wait=3600  from_time=${TRAFFIC_STATS_RESET_TIMESTAMP}
    ${ignore_time}=  Subtract Date From Date  ${UP_EVENT_TIMESTAMP}  ${TRAFFIC_STATS_RESET_TIMESTAMP}  result_format=number
    IF  ${TRAFFIC_BLACKHOLE_DURATION} >= ${ignore_time}
      ${TRAFFIC_RECOVERY_TIME}=  Evaluate  ${TRAFFIC_BLACKHOLE_DURATION} - ${ignore_time}
    ELSE
      ${TRAFFIC_RECOVERY_TIME}=  Set Variable  0
    END
    Set Test Variable  ${TRAFFIC_RECOVERY_TIME}
    ${flows}=  ixia save flow stats  filename=${TEST_ID}_Traffic_05_After_Up_Event_Loss_Cleared
    ixia analyse verify all flows are under given packet loss duration value  flows=${flows}  value=${BASELINE_LOSS}  event=Traffic_05_After_Up_Event_Loss_Cleared
    ixia stop traffic items
    ${flows}=  ixia save flow stats  filename=${TEST_ID}_Traffic_06_Stopped
    IF  ${status}
      utility set test pass  [PASS] Ixia traffic is lossless after ${TRAFFIC_RECOVERY_TIME} seconds since reload event.
    ELSE
      utility set test fail  [FAIL] Ixia traffic is still showing some loss after ${TRAFFIC_RECOVERY_TIME} seconds since reload event.
    END


Compare parsed outputs from before down event (step 2) and after down event (step 4)
    iosxr compare parsed output for list of commands  command_list=${command_list}  parsed_1=${DUT_1_parsed_1}  parsed_2=${DUT_1_parsed_2}  parsed_1_desc=${DUT_1} Before Down Event  parsed_2_desc=${DUT_1} After Down Event  include_desc=${TRUE}  warn_only=${TRUE}

Compare parsed outputs from before down event (step 2) and after up event (step 8)
    iosxr compare parsed output for list of commands  command_list=${command_list}  parsed_1=${DUT_1_parsed_1}  parsed_2=${DUT_1_parsed_3}  parsed_1_desc=${DUT_1} Before Down Event  parsed_2_desc=${DUT_1} After Up Event  include_desc=${TRUE}  warn_only=${TRUE}
