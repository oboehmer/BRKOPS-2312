*** Settings ***
Library        pyats.robot.pyATSRobot
Library        unicon.robot.UniconRobot
Library        genie.libs.robot.GenieRobot
Suite Setup    setup test environment

*** Test Cases ***
Verify OSPF Neighbor
    ${result}=  parse "show ip ospf neighbor GigabitEthernet2 detail" on device "r1"
    check neighbor id       ${result}    10.0.0.2
    check neighbor state    ${result}    full

*** Keywords ***
setup test environment
    use testbed "testbed.yaml"
    connect to device "r1"

check neighbor id
    [Arguments]    ${result}    ${id}
    ${nbr_id}=     dq query   data=${result}    filters=contains('neighbors').get_values('neighbor_router_id')
    Should be Equal    ${nbr_id}[0]   ${id} 

check neighbor state
    [Arguments]    ${result}    ${state}
    ${nbr_state}=  dq query   data=${result}    filters=contains('neighbors').get_values('state')
    Should be Equal    ${nbr_state}[0]   ${state} 
