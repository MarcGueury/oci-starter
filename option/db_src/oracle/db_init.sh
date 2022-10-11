SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install SQL*Plus
sudo yum install -y oracle-instantclient-release-el7
sudo yum install -y oracle-instantclient-basic
sudo yum install -y oracle-instantclient-sqlplus

# Install the tables
cat > tnsnames.ora <<EOT
db  = $DB_URL
EOT

export TNS_ADMIN=$SCRIPT_DIR
sqlplus $DB_USER/$DB_PASSWORD@DB @oracle.sql
