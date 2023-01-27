*** Settings ***
Library        pyats.robot.pyATSRobot
Library        unicon.robot.UniconRobot
Library        genie.libs.robot.GenieRobot

Suite Setup    Run Keywords    use testbed "testbed.yaml"    AND    connect to all devices

*** Variables ***
${edge_device}        r3
${core_device}        r1
${route_positive}     10.100.99.0/24
${route_negative}     192.168.99.0/24

*** Test Cases ***
Positive route distribution test
    ${cmd}=    Set Variable    router static address-family ipv4 unicast ${route_positive} Null0
    configure "${cmd}" on device "${edge_device}"
    Sleep    1
    validate route on device    ${core_device}    ${route_positive}
    [Teardown]    configure "no ${cmd}" on device "${edge_device}"

Negative route distribution test
    ${cmd}=    Set Variable    router static address-family ipv4 unicast ${route_negative} Null0
    configure "${cmd}" on device "${edge_device}"
    Sleep    1
    Run Keyword and Expect Error    Route not found    
    ...    validate route on device    ${core_device}    ${route_negative}
    [Teardown]    configure "no ${cmd}" on device "${edge_device}"

*** Keywords ***
validate route on device
    [Arguments]    ${device}    ${prefix}
    ${output}=      parse "show ip route ospf" on device "${device}"
    ${routes}=      dq query    data=${output}    filters=contains('${prefix}')
    Should Not Be Empty    ${routes}    msg=Route not found
