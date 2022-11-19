export TOMCAT_HOME=/opt/tomcat

# Create tomcat user, disable login and give rights
# sudo useradd -s /bin/nologin -g opc -d $TOMCAT_HOME tomcat
sudo useradd -g opc -d $TOMCAT_HOME tomcat

sudo yum -y install wget
VER=10.0.27
cd /tmp
sudo mkdir -p /opt/tomcat
wget https://archive.apache.org/dist/tomcat/tomcat-10/v${VER}/bin/apache-tomcat-${VER}.tar.gz
sudo tar -xvf /tmp/apache-tomcat-$VER.tar.gz -C $TOMCAT_HOME --strip-components=1
sudo cp /home/opc/app/starter-1.0.war $TOMCAT_HOME/webapps
sed -i "s!##JDBC_URL##!$JDBC_URL!" /home/opc/app/start.sh
sudo mv /home/opc/app/start.sh $TOMCAT_HOME/bin/.

sudo chown -R tomcat: $TOMCAT_HOME
sudo sh -c "chmod +x $TOMCAT_HOME/bin/*.sh"
cat > /tmp/tomcat.service << EOF 
[Unit]
Description=Apache Tomcat Web Application Container
Wants=network.target
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/jre-openjdk
Environment=CATALINA_PID=$TOMCAT_HOME/temp/tomcat.pid
Environment=CATALINA_HOME=$TOMCAT_HOME
Environment='CATALINA_OPTS=-Xms512M -Xmx1G -Djava.net.preferIPv4Stack=true'
Environment='JAVA_OPTS=-Djava.awt.headless=true'

ExecStart=$TOMCAT_HOME/bin/start.sh
ExecStop=$TOMCAT_HOME/bin/shutdown.sh
SuccessExitStatus=143

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/tomcat.service /etc/systemd/system/tomcat.service 

sudo systemctl daemon-reload
