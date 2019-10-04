#!/bin/sh -e

DIRNAME=`dirname $0`
cd $DIRNAME
USAGE="$0"
if [ `id -u` != 0 ]; then
echo 'You must be root to run this script'
exit 1
fi

if [ $# -ge 1 ] ; then
	echo -e $USAGE
	exit 1
fi

echo "Building and Loading Policy"
set -x
make -f /usr/share/selinux/devel/Makefile db2.pp || exit
/usr/sbin/semodule -i db2.pp

# Generate a man page off the installed module
# Uncomment out the next line if you want a man page for this policy
# sepolicy manpage -p . -d db2_t


# Relabel files modified by the Db2 policy
/sbin/restorecon -F -R -v  /opt/ibm/db2 /var/db2


# Generate a rpm package for the newly generated policy
#pwd=$(pwd)
#rpmbuild --define "_sourcedir ${pwd}" --define "_specdir ${pwd}" --define "_builddir ${pwd}" --define "_srcrpmdir ${pwd}" --define "_rpmdir ${pwd}" --define "_buildrootdir ${pwd}/.build"  -ba db2_selinux.spec
