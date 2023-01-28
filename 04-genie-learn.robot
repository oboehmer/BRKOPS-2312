*** Settings ***
Library        pyats.robot.pyATSRobot
Library        unicon.robot.UniconRobot
Library        genie.libs.robot.GenieRobot
Library        Collections
Suite Setup    Run Keywords    use testbed "testbed.yaml"    AND    connect to all devices

*** Variables ***
&{OSPF_MODELS}                         # will contain parsed OSPF models from all devices
@{DEVICES}        r1    r2    r3       # r1,r2 are iosxe, r3 is iosxr device

*** Test Cases ***
Verify OSPF hello intervals
    [Documentation]    Check that no interface uses hello-interval <= 5 sec
    [Tags]    robot:continue-on-failure

    FOR    ${device}    IN    @{DEVICES}
        ${model}=     learn OSPF on device    ${device}
        ${result}=    dq query   data=${model}
        ...                      filters=value_operator('hello_interval', '<=', 5).get_values('[10]')

        Should Be Empty    ${result}    msg=Interfaces ${result} on ${device} have too low hello-interval
    END

*** Keywords ***
learn OSPF on device
    [Arguments]    ${device}
    ${result}=    learn "ospf" on device "${device}"
    # convert result to qdict.. a bit ugly
    ${qdict}=     Evaluate   genie.conf.base.utils.QDict($result.to_dict())
    Log Dictionary    ${qdict}
    RETURN    ${qdict}
