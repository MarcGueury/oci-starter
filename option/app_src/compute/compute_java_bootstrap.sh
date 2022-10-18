#!/bin/bash
# compute_java_bootstrap 
#
# Script that is runned once during the setup of a 
# - compute
# - with Java
if [[ -z "$TF_VAR_java_version" ]] || [[ -z "$JDBC_URL" ]]; then
  echo "Missing env variables"
  exit
fi

# -- App --------------------------------------------------------------------

if [ "$TF_VAR_language" == "NodeJS" ]; then
  # Install last version of NodeJS
  sudo yum install -y oracle-nodejs-release-el7 oracle-release-el7
  sudo yum install -y nodejs
  cd app
  npm install
  cd $HOME
else
  # Install the JVM (JDK or GraalVM)
  if [ "$TF_VAR_java_vm" == "GraalVM" ]; then
    # GraalVM
    if [ "$TF_VAR_java_version" == 8 ]; then
      sudo yum install -y graalvm21-ee-8-jdk.x86_64 
    elif [ "$TF_VAR_java_version" == 11 ]; then
      sudo yum install -y graalvm22-ee-11-jdk.x86_64
    elif [ "$TF_VAR_java_version" == 17 ]; then
      sudo yum install -y graalvm22-ee-17-jdk.x86_64 
    fi
    
  else
    # JDK 
    if [ "$TF_VAR_java_version" == 8 ]; then
      sudo yum install -y java-1.8.0-openjdk
    elif [ "$TF_VAR_java_version" == 11 ]; then
      sudo yum install -y jdk-11.x86_64  
    elif [ "$TF_VAR_java_version" == 17 ]; then
      sudo yum install -y jdk-17.x86_64  
    fi
  fi
fi

# Hardcode the connection to the DB in the start.sh
sed -i "s!##JDBC_URL##!$JDBC_URL!" app/start.sh 
sed -i "s!##DB_HOST##!$DB_HOST!" app/start.sh 
chmod +x app/start.sh

# Create an "app.service" that starts when the machine starts.
cat > /tmp/app.service << EOT
[Unit]
Description=App
After=network.target

[Service]
Type=simple
ExecStart=/home/opc/app/start.sh
TimeoutStartSec=0
User=opc

[Install]
WantedBy=default.target
EOT

sudo cp /tmp/app.service /etc/systemd/system
sudo chmod 664 /etc/systemd/system/app.service
sudo systemctl daemon-reload
sudo systemctl enable app.service
sudo systemctl start app.service

# -- UI --------------------------------------------------------------------
if [ -d ui ]; then
  # Install the yum repository containing nginx
  sudo rpm -Uvh http://nginx.org/packages/rhel/7/noarch/RPMS/nginx-release-rhel-7-0.el7.ngx.noarch.rpm
  # Install NGINX
  sudo yum install nginx -y > /tmp/yum_nginx.log
  
  #location /app/ { proxy_pass http://localhost:8080 }
  sudo sed -i '/#error_page.*/i location /app/ { proxy_pass http://localhost:8080/; }' /etc/nginx/conf.d/default.conf

  # SE Linux (for proxy_pass)
  sudo setsebool -P httpd_can_network_connect 1

  # Start it
  sudo systemctl enable nginx
  sudo systemctl start nginx

  # Copy the index file after the installation of nginx
  sudo cp -r ui/* /usr/share/nginx/html/

  # Firewalld
  sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
fi

# Firewalld
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

# -- Util -------------------------------------------------------------------
sudo yum install -y psmisc
