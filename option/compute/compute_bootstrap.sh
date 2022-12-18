#!/bin/bash
# compute_java_bootstrap 
#
# Script that is runned once during the setup of a 
# - compute
# - with Java
if [[ -z "$TF_VAR_language" ]]; then
  echo "Missing env variables"
  exit
fi


# -- Java --------------------------------------------------------------------
# Set up the correct Java / VM version
if [ "$TF_VAR_language" == "java" ]; then
  # Install the JVM (jdk or graalvm)
  if [ "$TF_VAR_java_vm" == "graalvm" ]; then
    # graalvm
    if [ "$TF_VAR_java_version" == 8 ]; then
      sudo yum install -y graalvm21-ee-8-jdk.x86_64 
      sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java8/bin/java
    elif [ "$TF_VAR_java_version" == 11 ]; then
      sudo yum install -y graalvm22-ee-11-jdk.x86_64
      sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java11/bin/java
    elif [ "$TF_VAR_java_version" == 17 ]; then
      sudo yum install -y graalvm22-ee-17-jdk.x86_64 
      sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java17/bin/java
    fi   
  else
    # jdk 
    if [ "$TF_VAR_java_version" == 8 ]; then
      sudo yum install -y java-1.8.0-openjdk
    elif [ "$TF_VAR_java_version" == 11 ]; then
      sudo yum install -y jdk-11.x86_64  
    elif [ "$TF_VAR_java_version" == 17 ]; then
      sudo yum install -y jdk-17.x86_64  
    fi
  fi
fi

# -- App --------------------------------------------------------------------
# Application Specific installation
if [ -f app/install.sh ]; then
  chmod +x app/install.sh
  app/install.sh
fi  

# -- app/start.sh -----------------------------------------------------------
if [ -f app/start.sh ]; then
  # Hardcode the connection to the DB in the start.sh
  if [ "$DB_URL" != "" ]; then
    sed -i "s!##JDBC_URL##!$JDBC_URL!" app/start.sh 
    sed -i "s!##DB_URL##!$DB_URL!" app/start.sh 
  fi  
  sed -i "s!##TF_VAR_java_vm##!$TF_VAR_java_vm!" app/start.sh   
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
  sudo systemctl restart app.service
fi

# -- UI --------------------------------------------------------------------
if [ -d ui ]; then
  # Install the yum repository containing nginx
  sudo rpm -Uvh http://nginx.org/packages/rhel/7/noarch/RPMS/nginx-release-rhel-7-0.el7.ngx.noarch.rpm
  # Install NGINX
  sudo yum install nginx -y > /tmp/yum_nginx.log
  
  # Default: location /app/ { proxy_pass http://localhost:8080 }
  sudo cp nginx_app.locations /etc/nginx/conf.d/.
  if grep -q nginx_app /etc/nginx/conf.d/default.conf; then
    echo "Include is already there"
  else
     echo not found
     sudo sed -i '/404.html/ a include conf.d/nginx_app.locations;' /etc/nginx/conf.d/default.conf
  fi

  # PHP or RUBY
  if [ -f app/nginx_app.conf ]; then
   sudo cp app/nginx_app.conf /etc/nginx/conf.d/.
  fi

  # SE Linux (for proxy_pass)
  sudo setsebool -P httpd_can_network_connect 1

  # Start it
  sudo systemctl enable nginx
  sudo systemctl restart nginx

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
