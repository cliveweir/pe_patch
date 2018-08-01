#!/bin/sh
#
# Generate cache of patch data for consumption by Puppet custom facts.
#

PATH=/usr/bin:/usr/sbin:/bin:/usr/local/bin

case $(/usr/local/bin/facter osfamily) in
  RedHat)
    PKGS=$(yum -q check-update | awk '/^[a-z]/ {print $1}')
    SECPKGS=$(yum -q --security check-update | awk '/^[a-z]/ {print $1}')
  ;;
  Debian)
    PKGS=$(apt upgrade -s 2>/dev/null | awk '$1 == "Inst" {print $2}')
    SECPKGS=$(apt upgrade -s 2>/dev/null | awk '$1 == "Inst" && /security/ {print $2}')
  ;;
  *)
    exit 1
  ;;
esac

DATADIR='/etc/os_patching'
UPDATEFILE="$DATADIR/package_updates"
SECUPDATEFILE="$DATADIR/security_package_updates"

if [ ! -d "${DATADIR}" ]
then
  /usr/bin/logger -p error -t os_patching_fact_generation.sh "Can't find ${DATADIR}, exiting"
  exit 1
fi

for UPDATE in $PKGS
do
  echo "$UPDATE" >> ${UPDATEFILE} || exit 1
done

for UPDATE in $SECPKGS
do
  echo "$UPDATE" >> ${SECUPDATEFILE} || exit 1
done

/usr/bin/logger -p info -t os_patching_fact_generation.sh "patch data fact refreshed"

exit 0
