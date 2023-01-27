from pyats import aetest


class CommonSetup(aetest.CommonSetup):

    @aetest.subsection
    def connect(self, testbed):
        # connect to all testbed devices
        testbed.devices.r1.connect()
        self.parent.parameters['uut'] = testbed.devices.r1


class VerifyOspfNeighbors(aetest.Testcase):

    @aetest.test
    def verify_ospf_neighbors(self, uut):
        output = uut.parse('show ip ospf neighbor GigabitEthernet2 detail')
        neighbor_rid = output.q.contains('neighbors').get_values('neighbor_router_id')[0]
        if neighbor_rid != '10.0.0.2':
            self.failed(f'Neighbor router id {neighbor_rid} is unexpected')
        neighbor_state = output.q.contains('neighbors').get_values('state')[0]
        if neighbor_state not in ['fulld']:
            self.failed(f'Neighbor state {neighbor_state} is unexpected')
        self.passed(f'Neighbor router {neighbor_rid} and state {neighbor_state} as expected')


class CommonCleanup(aetest.CommonCleanup):

    @aetest.subsection
    def subsection_cleanup_one(self, testbed):
        testbed.disconnect()
