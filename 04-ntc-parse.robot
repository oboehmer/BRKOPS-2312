*** Settings ***
Library        pyats.robot.pyATSRobot
Library        unicon.robot.UniconRobot
Library        ntc_templates/parse.py    AS   NTC
Library        Collections
Suite Setup    Run Keywords    use testbed "testbed.yaml"    AND    connect to devices "${{';'.join($DEVICES)}}"

*** Variables ***
@{DEVICES}        r1    r2        # only IOS devices

*** Test Cases ***
Check OSPF Database via NTC Templates
    [Tags]    robot:continue-on-failure

    ${cmd}=    Set Variable    show ip ospf database
    FOR    ${device}    IN    @{DEVICES}

        ${output}=    execute "${cmd}" on device "${device}"
        ${parsed}=    NTC.Parse Output    platform=cisco_ios    command=${cmd}    data=${output}

        # just logging the list, actual test is left for the reader ;-) 
        Log List    ${parsed}
    END
