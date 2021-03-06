#!/usr/bin/env bash
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distrbuted under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

main() {
 export CONTAINER_IP=$(hostname -i)

 echo "Registering $HOSTNAME consul node with consul cluster"
 consul agent -config-file=/etc/consul.json -server -node=$(hostname -s) -advertise=$CONTAINER_IP -client=0.0.0.0 -recursor=8.8.8.8  -recursor=192.168.0.1 -join ambari-server &

  if [ ! -n "$1" ] || [ "$1" = "local" ]
    then
      find /ambari/ambari-metrics/ambari-metrics-assembly/target/rpm -type f -name *.x86_64.rpm -print0 | xargs -0 yum install --disableplugin=fastestmirror -y

      yum --disableplugin=fastestmirror install -y /ambari/ambari-agent/target/rpm/ambari-agent/RPMS/x86_64/ambari-agent-*.x86_64.rpm
  else
    cd /etc/yum.repos.d
    wget $1
    yum -y install ambari-metrics ambari-agent
  fi

  ambari-agent reset $AMBARI_SERVER_HOSTNAME
  sed -i.bak '/\[agent\]/a system_resource_overrides=/etc/resource_overrides/' /etc/ambari-agent/conf/ambari-agent.ini
  ambari-agent start -v

  while true; do
    sleep 3
    tail -f /var/log/ambari-agent/ambari-agent.log
  done
}

main "$@"
