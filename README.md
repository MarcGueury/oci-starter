# oci-starter

## Usage:
### 1. Cloud Shell / Command Line 

- Go to OCI Home page.
- Start "Cloud Shell" icon on top/right

```
git clone https://github.com/MarcGueury/oci-starter 
cd oci-starter
./oci-starter.sh
./oci-starter.sh -prefix test -language java -deploy compute -db_password LiveLab__12345 
cd output
./build.sh
Then click on the UI_URL at then end of the build
```

To destroy:
```
cd output
./destroy.sh
> Confirm: yes
```


Best practice: 
- Run the command in compartment
    - Go to menu "Identity & Security"
    - Compartment
        - Find or create your compartment_id
```
...
./oci-starter.sh -compartment_ocid ocid1.compartment.oc1..xxx -prefix test -language java -deploy compute -db_password LiveLab__12345 
...
```

## 2. "Deploy to Oracle Cloud"

[ ![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/MarcGueury/oci-starter/archive/refs/heads/main.zip)

Just follow the wizard.

