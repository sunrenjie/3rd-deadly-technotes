#!/bin/sh

# Be sure to manually intall missing dependency packages of the whole system
# with commands like apt-get/yum/zypper if missing packages are complaining.
# For example, on debian we need to have:
# libffi-dev libmysqlclient-dev libpq-dev

# For optimization purposes, the python packages on which openstack packages
# are dependent could be pre-installed, in which case, installation of a
# fresh copy of openstack costs no more than one minute.

dir_root=/opt
dir_pvenv=/opt/osenv
dir_openstack_git=/src/openstack

echo Installing openstack packages to $dir_pvenv ...
virtualenv $dir_pvenv

# The order are arranged such that if A is dependent on B, then B is before A
# in line
packages1='
pycadf oslo.config oslo.rootwrap oslo.messaging
python-keystoneclient python-glanceclient python-neutronclient python-novaclient python-cinderclient
'

packages2='neutron nova'

for p in $packages1 $packages2; do
  d=$dir_openstack_git/$p
  $dir_pvenv/bin/pip install -r $d/requirements.txt  -r $d/test-requirements.txt
  # install the package itself as editable
  $dir_pvenv/bin/pip install -e $dir
done

