#!/usr/bin/env python3
# OCI Starter
#
# Script to create an OCI deployment scaffold with application source code
#
# Authors: Marc Gueury & Ewan Slater
# Date: 2022-11-24
import sys
import os
import shutil
import json
from datetime import datetime
from distutils.dir_util import copy_tree

## constants ################################################################

ABORT = 'ABORT'
GIT = 'git'
CLI = 'cli'
GROUP='group'
ZIP = 'zip'
EXISTING = 'existing'
NEW = 'new'
TO_FILL = "__TO_FILL__"
BASIS_DIR = "basis"

## globals ##################################################################

output_dir = "output"
zip_dir = ""
a_group_common = []

## functions ################################################################

def title(t):
    s = "-- " + t + " "
    return s.ljust(78, '-')


def script_name():
    return os.path.basename(__file__)


def get_mode():
    return params['mode']


def prog_arg_list():
    arr = sys.argv.copy()
    arr.pop(0)
    return arr


def prog_arg_dict():
    return list_to_dict(prog_arg_list())


MANDATORY_OPTIONS = {
    CLI: ['-language', '-deploy', '-db_password'],
    GROUP: ['-group_name','-group_common','-db_password']
}

def mandatory_options(mode):
    return MANDATORY_OPTIONS[mode]


default_options = {
    '-prefix': 'starter',
    '-java_framework': 'springboot',
    '-java_vm': 'jdk',
    '-java_version': '17',
    '-ui': 'html',
    '-database': 'atp',
    '-license': 'included',
    '-mode': CLI,
    '-infra_as_code': 'terraform_local',
}

no_default_options = ['-compartment_ocid', '-oke_ocid', '-vcn_ocid',
                      '-atp_ocid', '-db_ocid', '-db_compartment_ocid', '-pdb_ocid', '-mysql_ocid',
                      '-db_user', '-fnapp_ocid', '-apigw_ocid', '-bastion_ocid', '-auth_token',
                      '-subnet_ocid','-public_subnet_ocid','-private_subnet_ocid','-shape']

# hidden_options - allowed but not advertised
hidden_options = ['-zip', '-group_common','-group_name']


def allowed_options():
    return list(default_options.keys()) + hidden_options \
        + mandatory_options(mode) + no_default_options


allowed_values = {
    '-language': {'java', 'node', 'python', 'dotnet', 'go', 'php', 'ords', 'none'},
    '-deploy': {'compute', 'kubernetes', 'function', 'container_instance', 'ci'},
    '-java_framework': {'springboot', 'helidon', 'tomcat', 'micronaut'},
    '-java_vm': {'jdk', 'graalvm', 'graalvm-native'},
    '-java_version': {'8', '11', '17'},
    '-kubernetes': {'oke', 'docker'},
    '-ui': {'html', 'jet', 'angular', 'reactjs', 'jsp', 'php', 'api', 'none'},
    '-database': {'atp', 'database', 'pluggable', 'mysql', 'none'},
    '-license': {'included', 'LICENSE_INCLUDED', 'byol', 'BRING_YOUR_OWN_LICENSE'},
    '-infra_as_code': {'terraform_local', 'terraform_object_storage', 'resource_manager'},
    '-mode': {CLI, GIT, ZIP},
    '-shape': {'amd','freetier_amd','ampere'}
}


def check_values():
    illegals = {}
    for arg in allowed_values:
        arg_val = prog_arg_dict().get(arg)
        if arg_val is not None:
            if arg_val not in allowed_values[arg]:
                illegals[arg] = arg_val
    return illegals


def get_tf_var(param):
    special_case = {
        'database': 'TF_VAR_db_strategy',
        'deploy': 'TF_VAR_deploy_strategy',
        'license': 'TF_VAR_license_model',
        'ui': 'TF_VAR_ui_strategy'
    }.get(param)
    if special_case is not None:
        return special_case
    else:
        return 'TF_VAR_' + param


def longhand(key, abbreviations):
    current = params[key]
    if current in abbreviations:
        return abbreviations[current]
    else:
        return current


def db_rules():
    params['database'] = longhand(
        'database', {'atp': 'autonomous', 'dbsystem': 'database'})

    if params.get('database') != 'autonomous' and params.get('language') == 'ords':
        error(f'OCI starter only supports ORDS on ATP (Autonomous)')
    if params.get('database') == 'pluggable':
        if (params.get('db_ocid') is None and params.get('pdb_ocid') is None):
            error(f'Pluggable Database needs an existing DB_OCID or PDB_OCID')
    if params.get('db_user') == None:
        default_users = {'autonomous': 'admin', 'database': 'system',
                         'pluggable': 'system',  'mysql': 'root', 'none': ''}
        params['db_user'] = default_users[params['database']]


def language_rules():
    if params.get('language') != 'java':
        params.pop('java_framework')
        params.pop('java_vm')
        params.pop('java_version')
    elif params.get('java_framework') == 'helidon' and params.get('java_version') != '17':
        warning('Helidon only supports Java 17. Forcing Java version to 17')
        params['java_version'] = 17


def kubernetes_rules():
    if 'deploy' in params:
      params['deploy'] = longhand('deploy', {'oke': 'kubernetes', 'ci': 'container_instance'})


def vcn_rules():
    if 'subnet_ocid' in params:
        params['public_subnet_ocid'] = params['subnet_ocid']
        params['private_subnet_ocid'] = params['subnet_ocid']
        params.pop('subnet_ocid')
    if 'vcn_ocid' in params and 'public_subnet_ocid' not in params:
        error('-subnet_ocid or required for -vcn_ocid')
    elif 'vcn_ocid' not in params and 'public_subnet_ocid' in params:
        error('-vcn_ocid required for -subnet_ocid')
    
 

def ui_rules():
    params['ui'] = longhand('ui', {'reactjs': 'ReactJS'})
    if params.get('ui') == 'jsp':
        params['language'] = 'java'
        params['java_framework'] = 'tomcat'
    elif params.get('ui') == 'php':
        params['language'] = 'php'
    elif params.get('ui') == 'ruby':
        params['language'] = 'ruby'


def auth_token_rules():
    if params.get('deploy') != 'compute' and params.get('auth_token') is None:
        warning('-auth_token is not set. Will need to be set in env.sh')
        params['auth_token'] = TO_FILL


def compartment_rules():
    if params.get('compartment_ocid') is None:
        warning(
            '-compartment_ocid is not set. Components will be created in root compartment. Shame on you!')


def license_rules():
    license_model = os.getenv('LICENSE_MODEL')
    if license_model is not None:
        params['license'] = license_model
    params['license'] = longhand(
        'license', {'included': 'LICENSE_INCLUDED', 'byol': 'BRING_YOUR_OWN_LICENSE'})


def zip_rules():
    if 'zip' in params:
        global output_dir, zip_dir
        if 'group_name' in params:
             zip_dir = params['group_name']
        else:
             zip_dir = params['prefix']
        output_dir = "zip" + os.sep + params['zip'] + os.sep + zip_dir
        file_output('zip' + os.sep + params['zip'] + '.param', [json.dumps(params)])


def group_common_rules():
    if 'group_name' in params:
        global a_group_common 
        a_group_common=params['group_common'].split(',')


def shape_rules():
    if 'shape' in params:
        if params.get('shape')=='freetier_amd':
            params['instance_shape'] = 'VM.Standard.E2.1.Micro'
            params['instance_shape_config_memory_in_gbs'] = 1
        if params.get('shape')=='ampere':
            params['instance_shape'] = 'VM.Standard.A1.Flex'
            params['instance_shape_config_memory_in_gbs'] = 6
        params.pop('shape')


def apply_rules():
    zip_rules()
    group_common_rules()
    language_rules()
    kubernetes_rules()
    ui_rules()
    db_rules()
    vcn_rules()
    auth_token_rules()
    compartment_rules()
    license_rules()
    shape_rules()


def error(msg):
    errors.append(f'Error: {msg}')


def warning(msg):
    warnings.append(f'WARNING: {msg}')


def print_warnings():
    print(get_warnings())


def get_warnings():
    s = ''
    for warning in warnings:
        s += (f'{warning}\n')
    return s


def help():
    message = f'''
Usage: {script_name()} [OPTIONS]

oci-starter.sh
   -apigw_ocid (optional)
   -atp_ocid (optional)
   -auth_token (optional)
   -bastion_ocid' (optional)
   -compartment_ocid (default tenancy_ocid)
   -database (default atp | dbsystem | pluggable | mysql | none )
   -db_ocid (optional)
   -db_password (mandatory)
   -db_user (default admin)
   -deploy (mandatory) compute | kubernetes | function | container_instance 
   -fnapp_ocid (optional)
   -group_common (optional) atp | database | mysql | fnapp | apigw | oke | jms 
   -group_name (optional)
   -java_framework (default helidon | springboot | tomcat)
   -java_version (default 17 | 11 | 8)
   -java_vm (default jdk | graalvm)  
   -kubernetes (default oke | docker) 
   -language (mandatory) java | node | python | dotnet | ords 
   -license (default included | byol )
   -mysql_ocid (optional)
   -oke_ocid (optional)
   -prefix (default starter)
   -public_subnet_ocid (optional)
   -private_subnet_ocid (optional)
   -shape (optional freetier)
   -ui (default html | reactjs | jet | angular | none) 
   -vcn_ocid (optional)

'''
    if len(unknown_params) > 0:
        s = ''
        for unknown in unknown_params:
            s += f'{unknown} '
        message += f'Unknown parameter(s):{s}\n'
    if len(missing_params) > 0:
        s = ''
        for missing in missing_params:
            s += f'{missing} '
        message += f'Missing parameter(s):{s}\n'
    if len(illegal_params) > 0:
        s = ''
        for arg in illegal_params:
            s += f'Illegal value: "{illegal_params[arg]}" found for {arg}.  Permitted values: {allowed_values[arg]}\n'
        message += s
    if len(errors) > 0:
        s = ''
        for error in errors:
            s += f'{error}\n'
        message += s
    message += get_warnings()
    return message


def list_to_dict(a_list):
    it = iter(a_list)
    res_dct = dict(zip(it, it))
    return res_dct


def deprefix_keys(a_dict, prefix_length=1):
    return dict(map(lambda x: (x[0][prefix_length:], x[1]), a_dict.items()))


def missing_parameters(supplied_params, expected_params):
    expected_set = set(expected_params)
    supplied_set = set(supplied_params)
    for supplied in supplied_set:
        expected_set.discard(supplied)
    return list(expected_set)


def get_params():
    return deprefix_keys({**default_options, **prog_arg_dict()})


def git_params():
    keys = ['git_url', 'repository_name', 'oci_username']
    values = prog_arg_list()
    return dict(zip(keys, values))


def readme_contents():
    if 'group_name' in params:
        contents = ['''## OCI-Starter - Common Resources
### Usage 

### Commands
- build_group.sh   : Build first the Common Resources (group_common), then other directories
- destroy_group.sh : Destroy other directories, then the Common Resources

- group_common
    - build.sh     : Create the Common Resources using Terraform
    - destroy.sh   : Destroy the objects created by Terraform
    - env.sh       : Contains the settings of the project

### Directories
- group_common/src : Sources files
    - terraform    : Terraform scripts (Command: plan.sh / apply.sh)

### After Build
- group_common_env.sh : File created during the build.sh and imported in each application
- app1                : Directory with an application using "group_common_env.sh" 
- app2                : ...
...
    '''
                ]
    else:
        contents = ['''## OCI-Starter
### Usage 

### Commands
- build.sh      : Build the whole program: Run Terraform, Configure the DB, Build the App, Build the UI
- destroy.sh    : Destroy the objects created by Terraform
- env.sh        : Contains the settings of your project

### Directories
- src           : Sources files
    - app       : Source of the Backend Application (Command: build_app.sh)
    - ui        : Source of the User Interface (Command: build_ui.sh)
    - db        : SQL files of the database
    - terraform : Terraform scripts (Command: plan.sh / apply.sh)'''
                ]
        if params['deploy'] == 'compute':
            contents.append(
                "  - compute     : Contains the deployment files to Compute")
        elif params['deploy'] == 'kubernetes':
            contents.append(
                "  - oke         : Contains the deployment files to Kubernetes")

    contents.append('\n### Next Steps:')
    if TO_FILL in params.values():
        if 'group_name' in params:
            contents.append("- Edit the file group_common/env.sh. Some variables need to be filled:")
        else:
            contents.append("- Edit the file env.sh. Some variables need to be filled:")
        contents.append("```")
        for param, value in params.items():
            if value == TO_FILL:
                contents.append(
                    f'export {get_tf_var(param)}="{params[param]}"')
        contents.append("```")
    contents.append("\n- Run:")
    if 'group_name' in params:
        contents.append("  # Build first the group common resources (group_common), then other directories")
        contents.append(f"  cd {params['group_name']}")
        contents.append("  ./build_group.sh")       
    else:
        contents.append(f"  cd {params['prefix']}")
        contents.append("  ./build.sh")
    return contents

def env_param_list():
    env_params = list(params.keys())
    exclude = ['mode', 'infra_as_code', 'zip', 'prefix']
    if params.get('language') != 'java' or 'group_name' in params:
        exclude.extend(['java_vm', 'java_framework', 'java_version'])
    if 'group_name' in params:
        exclude.extend(['ui', 'database', 'language', 'deploy', 'db_user', 'group_name'])
    else:
        exclude.append('group_common')
    print(exclude)
    for x in exclude:
        if x in env_params:
            env_params.remove(x)
    return env_params

def env_sh_contents():
    env_params = env_param_list()
    print(env_params)
    timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M-%S-%f")
    contents = ['#!/bin/bash']
    contents.append(
        'SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )')
    contents.append(f'export OCI_STARTER_CREATION_DATE={timestamp}')
    contents.append(f'export OCI_STARTER_VERSION=1.4')
    contents.append('')
    contents.append('# Env Variables')
    if 'group_name' in params:
        prefix = params["group_name"]
    else:
        prefix = params["prefix"]
    contents.append(f'export TF_VAR_prefix="{prefix}"')
    contents.append('')

    group_common_contents = []
    for param in env_params:
        if param.endswith("_ocid") or param in ["db_password", "auth_token", "license"]:
            tf_var_comment(group_common_contents, param)
            group_common_contents.append(f'export {get_tf_var(param)}="{params[param]}"')
        else:
            tf_var_comment(contents, param)
            contents.append(f'export {get_tf_var(param)}="{params[param]}"')
    contents.append('')
    if 'group_name' in params:
        contents.append("if [ -f $SCRIPT_DIR/../../group_common_env.sh ]; then")      
        contents.append("  . $SCRIPT_DIR/../../group_common_env.sh")      
    else:
        contents.append("if [ -f $SCRIPT_DIR/../group_common_env.sh ]; then")      
        contents.append("  . $SCRIPT_DIR/../group_common_env.sh")      
    contents.append("else")      
    if params.get('compartment_ocid') == None:
        contents.append('  # export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx')       

    for x in group_common_contents:
        contents.append("  " + x)

    contents.append('')
    contents.append('  # Landing Zone')
    contents.append('  # export TF_VAR_lz_appdev_cmp_ocid=$TF_VAR_compartment_ocid')
    contents.append('  # export TF_VAR_lz_database_cmp_ocid=$TF_VAR_compartment_ocid')
    contents.append('  # export TF_VAR_lz_network_cmp_ocid=$TF_VAR_compartment_ocid')
    contents.append('  # export TF_VAR_lz_security_cmp_ocid=$TF_VAR_compartment_ocid')

    contents.append("fi")      

    contents.append('')
    contents.append(
        '# Get other env variables automatically (-silent flag can be passed)')
    contents.append('. $SCRIPT_DIR/bin/auto_env.sh $1')
    return contents


def tf_var_comment(contents, param):
    comments = {
        'auth_token': ['See doc: https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrygettingauthtoken.htm'],
        'db_password': ['Requires at least 12 characters, 2 letters in lowercase, 2 in uppercase, 2 numbers, 2 special characters. Ex: LiveLab__12345', 'If not filled, it will be generated randomly during the first build.'],
        'license': ['BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED']
    }.get(param)
    if comments is not None:
        for comment in comments:
            contents.append(f'# {get_tf_var(param)} : {comment}')


def write_env_sh():
    output_path = output_dir + os.sep + 'env.sh'
    file_output(output_path, env_sh_contents())
    os.chmod(output_path, 0o755)


def write_readme():
    output_path = output_dir + os.sep + 'README.md'
    file_output(output_path, readme_contents())


def file_output(file_path, contents):
    output_file = open(file_path, "w")
    output_file.writelines('%s\n' % line for line in contents)
    output_file.close()


## COPY FILES ###############################################################
def copy_basis(basis_dir=BASIS_DIR):
    print( "output_dir="+output_dir )
    copy_tree(basis_dir, output_dir)

def output_replace(old_string, new_string, filename):
    # Safely read the input filename using 'with'
    path = output_dir + os.sep + filename
    if os.path.exists(path):
        with open(path) as f:
            s = f.read()
            if old_string not in s:
                print('"{old_string}" not found in {filename}.'.format(**locals()))
                return

        # Safely write the changed content, if found in the file
        with open(path, 'w') as f:
            s = s.replace(old_string, new_string)
            f.write(s)

def cp_terraform(file1, file2=None):
    print("cp_terraform " + file1)
    shutil.copy2("option/terraform/"+file1, output_dir + "/src/terraform")

    # Append a second file
    if file2 is not None:
        print("append " + file2)
        # opening first file in append mode and second file in read mode
        f1 = open(output_dir + "/src/terraform/"+file1, 'a+')
        f2 = open("option/terraform/"+file2, 'r')
        # appending the contents of the second file to the first file
        f1.write('\n\n')
        f1.write(f2.read())
        f1.close()
        f2.close()

def output_copy_tree(src, target):
    copy_tree(src, output_dir + os.sep + target)

def output_move(src, target):
    shutil.move(output_dir + os.sep + src, output_dir + os.sep + target)

def output_mkdir(src):
    os.mkdir(output_dir+ os.sep + src)

def output_rm_tree(src):
    shutil.rmtree(output_dir + os.sep + src)
 
def cp_dir_src_db(db_type):
    print("cp_dir_src_db "+db_type)
    output_copy_tree("option/src/db/"+db_type, "src/db")

# Copy the terraform for APIGW
def cp_terraform_apigw(append_tf):
    if params['language'] == "ords":
        app_url = "${local.ords_url}/starter/module/$${request.path[pathname]}"
    elif params['language'] == "java" and params['java_framework'] == "tomcat":
        app_url = "http://${local.apigw_dest_private_ip}:8080/starter-1.0/$${request.path[pathname]}"
    else:
        app_url = "http://${local.apigw_dest_private_ip}:8080/$${request.path[pathname]}" 

    if 'apigw_ocid' in params:
        cp_terraform("apigw_existing.tf", append_tf)
        output_replace('##APP_URL##', app_url,"src/terraform/apigw_existing.tf")
    else:
        cp_terraform("apigw.tf", append_tf)
        output_replace('##APP_URL##', app_url, "src/terraform/apigw.tf")    

#----------------------------------------------------------------------------
# Create Directory (shared for group_common and output)
def create_dir_shared():
    copy_basis()
    write_env_sh()
    write_readme()

    # -- Infrastructure As Code ---------------------------------------------
    # Default state local
    if params.get('infra_as_code') == "resource_manager":
        output_copy_tree("option/infra_as_code/resource_manager", "src/terraform")
    elif params.get('infra_as_code') == "terraform_object_storage":
        output_copy_tree("option/infra_as_code/terraform_object_storage", "src/terraform")
    else:
        output_copy_tree("option/infra_as_code/terraform_local", "src/terraform")

    # -- Network ------------------------------------------------------------
    if 'vcn_ocid' in params:
        cp_terraform("network_existing.tf")
    else:
        cp_terraform("network.tf")

    # -- Bastion ------------------------------------------------------------
    if 'bastion_ocid' in params:
        cp_terraform("bastion_existing.tf")
    else:
        cp_terraform("bastion.tf")

#----------------------------------------------------------------------------
# Create Output Directory
def create_output_dir():
    create_dir_shared()

    # -- APP ----------------------------------------------------------------
    if params['language'] == "none":
        output_rm_tree("src/app")
    else:
        if params.get('deploy') == "function":
            app = "fn/fn_"+params['language']
        else:
            app = params['language']
            if params['language'] == "java":
                app = "java_" + params['java_framework']

        if params['database'] == "autonomous" or params['database'] == "database" or params['database'] == "pluggable":
            app_db = "oracle"
        elif params['database'] == "mysql":
            app_db = "mysql"
        elif params['database'] == "none":
            app_db = "none"

        app_dir = app+"_"+app_db
        print("app_dir="+app_dir)

        # Function Common
        if params.get('deploy') == "function":
            output_copy_tree("option/src/app/fn/fn_common", "src/app")

        # Generic version for Oracle DB
        if os.path.exists("option/src/app/"+app):
            output_copy_tree("option/src/app/"+app, "src/app")

        # Overwrite the generic version (ex for mysql)
        if os.path.exists("option/src/app/"+app_dir):
            output_copy_tree("option/src/app/"+app_dir, "src/app")

        if params['language'] == "java":
            # FROM ghcr.io/graalvm/jdk:java17
            # FROM openjdk:17
            # FROM openjdk:17-jdk-slim
            if os.path.exists(output_dir + "/src/app/Dockerfile"):
                if params['java_vm'] == "graalvm":
                    output_replace('##DOCKER_IMAGE##', 'ghcr.io/graalvm/jdk:java17', "src/app/Dockerfile")
                else:
                    output_replace('##DOCKER_IMAGE##', 'openjdk:17-jdk-slim', "src/app/Dockerfile")

    # -- User Interface -----------------------------------------------------
    if params.get('ui') == "none":
        print("No UI")
        output_rm_tree("src/ui")
    elif params.get('ui') == "api": 
        print("API Only")
        output_rm_tree("src/ui")   
        if params.get('deploy') == "compute":
            cp_terraform_apigw("apigw_compute_append.tf")          
    else:
        ui_lower = params.get('ui').lower()
        output_copy_tree("option/src/ui/"+ui_lower, "src/ui")

    # -- Deployment ---------------------------------------------------------
    if params['language'] != "none":
        if params.get('deploy') == "kubernetes":
            if 'oke_ocid' in params:
                cp_terraform("oke_existing.tf", "oke_append.tf")
            else:
                cp_terraform("oke.tf", "oke_append.tf")
            output_mkdir("src/oke")
            output_copy_tree("option/oke", "src/oke")
            output_move("src/oke/oke_deploy.sh", "bin/oke_deploy.sh")
            output_move("src/oke/oke_destroy.sh", "bin/oke_destroy.sh")

            if os.path.exists(output_dir+"/src/app/ingress-app.yaml"):
                output_move("src/app/ingress-app.yaml", "src/oke/ingress-app.yaml")

            output_replace('##PREFIX##', params["prefix"], "src/app/app.yaml")
            output_replace('##PREFIX##', params["prefix"], "src/ui/ui.yaml")
            output_replace('##PREFIX##', params["prefix"], "src/oke/ingress-app.yaml")
            output_replace('##PREFIX##', params["prefix"], "src/oke/ingress-ui.yaml")

        elif params.get('deploy') == "function":
            if 'fnapp_ocid' in params:
                cp_terraform("function_existing.tf", "function_append.tf")
            else:
                cp_terraform("function.tf", "function_append.tf")
                cp_terraform("log_group.tf")
            if params['language'] == "ords":
                apigw_append = "apigw_fn_ords_append.tf"
            else:
                apigw_append = "apigw_fn_append.tf"
            if 'apigw_ocid' in params:
                cp_terraform("apigw_existing.tf", apigw_append)
            else:
                cp_terraform("apigw.tf", apigw_append)

        elif params.get('deploy') == "compute":
            cp_terraform("compute.tf")
            output_mkdir("src/compute")
            output_copy_tree("option/compute", "src/compute")

        elif params.get('deploy') == "container_instance":
            if 'group_common' not in params:
                cp_terraform("container_instance_policy.tf")
            if params.get('database') == "none":
                cp_terraform("container_instance_nodb.tf")
            else:
                cp_terraform("container_instance.tf")

            # output_mkdir src/container_instance
            output_copy_tree("option/container_instance", "bin")
            cp_terraform_apigw("apigw_ci_append.tf")          

    # -- Database ----------------------------------------------------------------
    if params.get('database') != "none":
        cp_terraform("output.tf")
        output_mkdir("src/db")

        if params.get('database') == "autonomous":
            cp_dir_src_db("oracle")
            if 'atp_ocid' in params:
                cp_terraform("atp_existing.tf", "atp_append.tf")
            else:
                cp_terraform("atp.tf", "atp_append.tf")

        if params.get('database') == "database":
            cp_dir_src_db("oracle")
            if 'db_ocid' in params:
                cp_terraform("dbsystem_existing.tf", "dbsystem_append.tf")
            else:
                cp_terraform("dbsystem.tf", "dbsystem_append.tf")

        if params.get('database') == "pluggable":
            cp_dir_src_db("oracle")
            if 'pdb_ocid' in params:
                cp_terraform("dbsystem_pluggable_existing.tf")
            else:
                cp_terraform("dbsystem_existing.tf", "dbsystem_pluggable.tf")

        if params.get('database') == "mysql":
            cp_dir_src_db("mysql")
            if 'mysql_ocid' in params:
                cp_terraform("mysql_existing.tf", "mysql_append.tf")
            else:
                cp_terraform("mysql.tf", "mysql_append.tf")

    if os.path.exists(output_dir + "/src/app/oracle.sql"):
        output_move("src/app/oracle.sql", "src/db/oracle.sql")

#----------------------------------------------------------------------------
# Create group_common Directory
def create_group_common_dir():
    create_dir_shared()

    # -- APP ----------------------------------------------------------------
    output_copy_tree("option/src/app/group_common", "src/app")
    os.remove(output_dir + "/src/app/app.yaml")

    # -- User Interface -----------------------------------------------------
    output_rm_tree("src/ui")

    # -- Common -------------------------------------------------------------
    if "atp" in a_group_common:
        if 'atp_ocid' in params:
            cp_terraform("atp_existing.tf")
        else:
            cp_terraform("atp.tf")

    if "database" in a_group_common:
        if 'db_ocid' in params:
            cp_terraform("dbsystem_existing.tf")
        else:
            cp_terraform("dbsystem.tf")

    if "mysql" in a_group_common:
        if 'mysql_ocid' in params:
            cp_terraform("mysql_existing.tf")
        else:
            cp_terraform("mysql.tf")

    if 'oke' in a_group_common:
        if 'oke_ocid' in params:
            cp_terraform("oke_existing.tf", "oke_append.tf")
        else:
            cp_terraform("oke.tf", "oke_append.tf")
            shutil.copy2("option/oke/oke_destroy.sh", output_dir +"/bin")

    if 'fnapp' in a_group_common:
        if 'fnapp_ocid' in params:
            cp_terraform("function_existing.tf")
        else:
            cp_terraform("function.tf")
            cp_terraform("log_group.tf")

    if 'apigw' in a_group_common:
        if 'apigw_ocid' in params:
            cp_terraform("apigw_existing.tf")
        else:
            cp_terraform("apigw.tf")

    if 'jms' in a_group_common:
        if 'jms_ocid' in params:
            cp_terraform("jms_existing.tf")
        else:
            cp_terraform("jms.tf")            
            cp_terraform("log_group.tf")

    # Container Instance Common
    cp_terraform("container_instance_policy.tf")


    allfiles = os.listdir(output_dir)
    allfiles.remove('README.md')
    # Create a group directory
    output_mkdir('group_common')
    # iterate on all files to move them to 'group_common'
    for f in allfiles:
        os.rename(output_dir + os.sep + f, output_dir + os.sep + 'group_common' + os.sep + f)

    output_copy_tree("option/group", ".")
    
#----------------------------------------------------------------------------

# the script
print(title(script_name()))

script_dir = os.getcwd()

params = get_params()
mode = get_mode()
unknown_params = missing_parameters(allowed_options(), prog_arg_dict().keys())
illegal_params = check_values()
if 'group_name' in params:
  missing_params = missing_parameters(prog_arg_dict().keys(), mandatory_options(GROUP))
else:  
  missing_params = missing_parameters(prog_arg_dict().keys(), mandatory_options(mode))

if len(unknown_params) > 0 or len(illegal_params) > 0 or len(missing_params) > 0:
    mode = ABORT

warnings = []
errors = []

if mode == CLI:
    apply_rules()
    if len(errors) > 0:
        mode = ABORT
    elif os.path.isdir(output_dir):
        print("Output dir exists already.")
        mode = ABORT
    else:
        print_warnings()

if mode == GIT:
    print("GIT mode currently not implemented.")
    # git clone $GIT_URL
    # cp ../mode/git/* $REPOSITORY_NAME/.
    exit()

if mode == ABORT:
    print(help())
    exit()

print(f'Mode: {mode}')
print(f'params: {params}')

# -- Copy Files -------------------------------------------------------------
output_dir_orig = output_dir

# Create a group
if 'group_name' in params:
    create_group_common_dir()

# Add parameters to the creation if the project is to be used with a group
if 'group_common' in params:
    # For a new group, create the first application in a subdir
    if 'group_name' in params:
        del params['group_name']    
        output_dir = output_dir + os.sep + params['prefix']
    # The application will use the Common Resources created by group_name above.
    # del params['group_common']
    params['vcn_ocid'] = TO_FILL
    params['public_subnet_ocid'] = TO_FILL
    params['private_subnet_ocid'] = TO_FILL
    params['bastion_ocid'] = TO_FILL
    to_ocid = { "atp": "atp_ocid", "database": "db_ocid", "mysql": "mysql_ocid", "oke": "oke_ocid", "fnapp": "fnapp_ocid", "apigw": "apigw_ocid", "jms": "jms_ocid"}
    for x in a_group_common:
        if x in to_ocid:
            ocid = to_ocid[x]
            params[ocid] = TO_FILL

if 'deploy' in params:
    create_output_dir()

# -- Done --------------------------------------------------------------------
title("Done")
print("Directory "+output_dir+" created.")

# -- Post Creation -----------------------------------------------------------

if mode == GIT:
    print("GIT mode currently not implemented.")
    # git config --local user.email "test@example.com"
    # git config --local user.name "${OCI_USERNAME}"
    # git add .
    # git commit -m "added latest files"
    # git push origin main

elif "zip" in params:
    # The goal is to have a file that when uncompressed create a directory prefix.
    shutil.make_archive("zip"+os.sep+params['zip'], format='zip',root_dir="zip"+os.sep+params['zip'], base_dir=zip_dir)
    print("Zip file created: zip"+os.sep+params['zip']+".zip")
else:
    print()
    readme= output_dir_orig + os.sep + "README.md"
    with open(readme, 'r') as fin:
        print(fin.read())
