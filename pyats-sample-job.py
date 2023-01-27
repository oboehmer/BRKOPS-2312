# run this file with
#
#   pyats run job pyats-sample-job.py --testbed-file testbed.yaml

# see https://pubhub.devnetcloud.com/media/pyats/docs/easypy/jobfile.html
# for how job files work

import os
from pyats.easypy import run

# compute the script path from this location
SCRIPT_PATH = os.path.dirname(__file__)


def main(runtime):
    '''job file entrypoint'''

    # run script
    run(testscript=os.path.join(SCRIPT_PATH, 'pyats-sample-script.py'),
        runtime=runtime)
