#!/bin/bash

if [[ `id -u` != "0" ]] ; then
  echo "You must be root to run this script"
  exit -1
fi

this_script_path=`realpath $0`
this_script_name=`basename $this_script_path`
this_script_dir=`dirname $this_script_path`

. ${this_script_dir}/env.sh

archive=$1
archive="${archive:-${app_name}.tar.gz}"
echo "Archive is ${archive}"
if [ ! -f ${archive} ]; then
  echo "Archive ${archive} does not exist"
  exit 1
fi

echo "User account ${appuser}..."
useradd -M -s /usr/sbin/nologin ${appuser}
usermod -a -G plugdev ${appuser}
mkdir -p ${appdir}
chown -R ${appuser}:${appuser} ${appdir}

echo "Extracting files to ${appdir}..."
tar -zx --overwrite -C ${appdir} -f ${archive}

echo "Stopping old services..."
systemctl disable ${service_name}.service 2>/dev/null
systemctl stop ${service_name}.service 2>/dev/null

echo "Installing service file ${appdir}/${service_name}.service..."

rm -f ${appdir}/${service_name}.service
cat <<EOT >> ${appdir}/${service_name}.service
[Unit]
Description=RTL-SDR Homebridge
After=network-online.target

[Service]
Environment="SHELL=/bin/bash"
User=${appuser}
WorkingDirectory=${appdir}/${app_name}
ExecStart=${appdir}/${app_name}/bin/${app_name} start

[Install]
WantedBy=multi-user.target
EOT

chmod 640 ${appdir}/${service_name}.service

chown -R ${appuser}:${appuser} ${appdir}

echo "Enabling service..."
systemctl enable ${appdir}/${service_name}.service
systemctl daemon-reload
systemctl start ${service_name}.service

echo "Done"
