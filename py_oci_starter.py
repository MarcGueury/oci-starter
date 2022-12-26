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

#  constants
ABORT = 'ABORT'
GIT = 'git'
CLI = 'cli'
ZIP = 'zip'
EXISTING = 'existing'
NEW = 'new'
TO_FILL = "__TO_FILL__"
OUTPUT_DIR = "output"
BASIS_DIR = "basis"
a_common = []

#  functions


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
    CLI: ['-language', '-deploy', '-db_password']
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
                      '-subnet_ocid']

# hidden_options - allowed but not advertised
hidden_options = ['-zip', '-common']


def allowed_options():
    return list(default_options.keys()) + hidden_options \
        + mandatory_options(mode) + no_default_options


allowed_values = {
    '-language': {'java', 'node', 'python', 'dotnet', 'go', 'php', 'ords', 'none'},
    '-deploy': {'compute', 'kubernetes', 'function', 'container_instance', 'ci'},
    '-java_framework': {'springboot', 'helidon', 'tomcat', 'micronaut'},
    '-java_vm': {'jdk', 'graalvm', 'graalvm_native'},
    '-java_version': {'8', '11', '17'},
    '-kubernetes': {'oke', 'docker'},
    '-ui': {'html', 'jet', 'angular', 'reactjs', 'jsp', 'php', 'none'},
    '-database': {'atp', 'database', 'pluggable', 'mysql', 'none'},
    '-license': {'included', 'LICENSE_INCLUDED', 'byol', 'BRING_YOUR_OWN_LICENSE'},
    '-infra_as_code': {'terraform_local', 'terraform_object_storage', 'resource_manager'},
    '-mode': {CLI, GIT, ZIP}
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
    params['deploy'] = longhand(
        'deploy', {'oke': 'kubernetes', 'ci': 'container_instance'})


def vcn_rules():
    if 'vcn_ocid' in params and 'subnet_ocid' not in params:
        error('-subnet_ocid required for -vcn_ocid')
    elif 'vcn_ocid' not in params and 'subnet_ocid' in params:
        error('-vcn_ocid required for -subnet_ocid')


def ui_rules():
    params['ui'] = longhand('ui', {'reactjs': 'ReactJS', 'none': 'None'})
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
        OUTPUT_DIR = params['zip']
        file_output('zip' + os.sep + OUTPUT_DIR +
                    '.param', [json.dumps(params)])


def common_rules():
    if 'common' in params:
        a_common = params['common'].split()
        params['language'] = 'common'
        params['ui'] = 'none'
        params['database'] = 'none'

def apply_rules():
    zip_rules()
    language_rules()
    kubernetes_rules()
    ui_rules()
    db_rules()
    vcn_rules()
    auth_token_rules()
    compartment_rules()
    license_rules()


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
   -java_framework (default helidon | springboot | tomcat)
   -java_version (default 17 | 11 | 8)
   -java_vm (default jdk | graalvm)  
   -kubernetes (default oke | docker) 
   -language (mandatory) java | node | python | dotnet | ords 
   -license (default included | byol )
   -mysql_ocid (optional)
   -oke_ocid (optional)
   -prefix (default starter)
   -subnet_ocid (optional)
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
    if 'common' in params:
        contents = ['''## OCI-Starter - Common Resources
### Usage 

### Commands
- common
    - build.sh   : Create the Common Resources
    - destroy.sh : Destroy the objects created by Terraform
    - env.sh     : Contains the settings of the project

### Directories
- common/src     : Sources files
    - terraform  : Terraform scripts (Command: plan.sh / apply.sh)

### After Build
- common.sh      : File created during the build.sh and imported in each application
- app1           : Directory with an application using "common.sh" 
- app2           : ...
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
        contents.append(
            "- Edit the file env.sh. Some variables need to be filled:")
        for param, value in params.items():
            if value == TO_FILL:
                contents.append(
                    f'export {get_tf_var(param)}="{params[param]}"')
    contents.append("\n- Run:")
    if mode == CLI:
        contents.append("  cd output")
    contents.append("  ./build.sh")
    return contents

def env_param_list():
    env_params = list(params.keys())
    exclude = ['mode', 'infra_as_code', 'zip']
    if params['language'] != 'java':
        exclude.extend(['java_vm', 'java_framework', 'java_version'])
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
    if params.get('compartment_ocid') == None:
        contents.append(
            '# export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx')
    for param in env_params:
        tf_var_comment(contents, param)
        contents.append(f'export {get_tf_var(param)}="{params[param]}"')
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


def write_env_sh(output_dir=OUTPUT_DIR):
    output_path = output_dir + os.sep + 'env.sh'
    file_output(output_path, env_sh_contents())
    os.chmod(output_path, 0o755)


def write_readme(output_dir=OUTPUT_DIR):
    output_path = output_dir + os.sep + 'README.md'
    file_output(output_path, readme_contents())


def file_output(file_path, contents):
    output_file = open(file_path, "w")
    output_file.writelines('%s\n' % line for line in contents)
    output_file.close()


def copy_basis(basis_dir=BASIS_DIR, output_dir=OUTPUT_DIR):
    copy_tree(basis_dir, output_dir)


def inplace_replace(old_string, new_string, filename):
    # Safely read the input filename using 'with'
    with open(filename) as f:
        s = f.read()
        if old_string not in s:
            print('"{old_string}" not found in {filename}.'.format(**locals()))
            return

    # Safely write the changed content, if found in the file
    with open(filename, 'w') as f:
        print(
            'Changing "{old_string}" to "{new_string}" in {filename}'.format(**locals()))
        s = s.replace(old_string, new_string)
        f.write(s)


def cp_terraform(file1, file2=None):
    print("cp_terraform " + file1)
    shutil.copy2("../option/terraform/"+file1, "src/terraform")

    # Append a second file
    if file2 is not None:
        print("append " + file2)
        # opening first file in append mode and second file in read mode
        f1 = open("src/terraform/"+file1, 'a+')
        f2 = open("../option/terraform/"+file2, 'r')
        # appending the contents of the second file to the first file
        f1.write('\n\n')
        f1.write(f2.read())
        f1.close()
        f2.close()


def cp_dir_src_db(db_type):
    print("cp_dir_src_db "+db_type)
    copy_tree("../option/src/db/"+db_type, "src/db")


# the script
print(title(script_name()))

script_dir = os.getcwd()

params = get_params()
mode = get_mode()
unknown_params = missing_parameters(allowed_options(), prog_arg_dict().keys())
illegal_params = check_values()
missing_params = missing_parameters(
    prog_arg_dict().keys(), mandatory_options(mode))
if len(unknown_params) > 0 or len(illegal_params) > 0 or len(missing_params) > 0:
    mode = ABORT

warnings = []
errors = []

if mode == CLI:
    apply_rules()
    if len(errors) > 0:
        mode = ABORT
    elif os.path.isdir(OUTPUT_DIR):
        print("Output dir exists already.")
        mode = ABORT
    else:
        print_warnings()
        copy_basis()
        write_env_sh()
        write_readme()

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
print("That's all Folks!")

## COPY FILES ##############################################################

os.chdir(OUTPUT_DIR)

# -- Infrastructure As Code -------------------------------------------------

# Default state local
if params.get('infra_as_code') == "resource_manager":
    copy_tree("../option/infra_as_code/resource_manager", "src/terraform")
elif params.get('infra_as_code') == "terraform_object_storage":
    copy_tree("../option/infra_as_code/terraform_object_storage", "src/terraform")
else:
    copy_tree("../option/infra_as_code/terraform_local", "src/terraform")

# -- APP ---------------------------------------------------------------------

if params['language'] == "none":
    shutil.rmtree("src/app")
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
        copy_tree("../option/src/app/fn/fn_common", "src/app")

    # Generic version for Oracle DB
    if os.path.exists("../option/src/app/"+app):
        copy_tree("../option/src/app/"+app, "src/app")

    # Overwrite the generic version (ex for mysql)
    if os.path.exists("../option/src/app/"+app_dir):
        copy_tree("../option/src/app/"+app_dir, "src/app")

    if params['language'] == "java":
        # FROM ghcr.io/graalvm/jdk:java17
        # FROM openjdk:17
        # FROM openjdk:17-jdk-slim
        if os.path.exists("src/app/Dockerfile"):
            if params['java_vm'] == "graalvm":
                inplace_replace(
                    '##DOCKER_IMAGE##', 'ghcr.io/graalvm/jdk:java17', "src/app/Dockerfile")
            else:
                inplace_replace('##DOCKER_IMAGE##',
                                'openjdk:17-jdk-slim', "src/app/Dockerfile")

    if params['language'] == "common":
        os.remove("src/app/app.yaml")

# -- User Interface ----------------------------------------------------------
if params.get('ui') == "none":
    print("No UI")
    shutil.rmtree("src/ui")
else:
    ui_lower = params.get('ui').lower()
    print("ui_lower=" + ui_lower)
    copy_tree("../option/src/ui/"+ui_lower, "src/ui")

# -- Network -----------------------------------------------------------------
if 'vcn_ocid' in params:
    cp_terraform("network_existing.tf")
else:
    cp_terraform("network.tf")

# -- Deployment --------------------------------------------------------------
if params['language'] != "none":
    if params.get('deploy') == "kubernetes":
        if 'oke_ocid' in params:
            cp_terraform("oke_existing.tf", "oke_append.tf")
        else:
            cp_terraform("oke.tf", "oke_append.tf")
        os.mkdir("src/oke")
        copy_tree("../option/oke", "src/oke")
        shutil.move("src/oke/oke_deploy.sh", "bin")
        shutil.move("src/oke/oke_destroy.sh", "bin")

        if os.path.exists("src/app/ingress-app.yaml"):
            shutil.move("src/app/ingress-app.yaml", "src/oke")

        inplace_replace('##PREFIX##', params["prefix"], "src/app/app.yaml")
        inplace_replace('##PREFIX##', params["prefix"], "src/ui/ui.yaml")
        inplace_replace(
            '##PREFIX##', params["prefix"], "src/oke/ingress-app.yaml")
        inplace_replace(
            '##PREFIX##', params["prefix"], "src/oke/ingress-ui.yaml")

    elif params.get('deploy') == "function":
        if 'fnapp_ocid' in params:
            cp_terraform("function_existing.tf", "function_append.tf")
        else:
            cp_terraform("function.tf", "function_append.tf")
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
        os.mkdir("src/compute")
        copy_tree("../option/compute", "src/compute")

    elif params.get('deploy') == "container_instance":
        cp_terraform("container_instance.tf")
        # mkdir src/container_instance
        copy_tree("../option/container_instance", "bin")

        if params['language'] == "ords":
            app_url = "${local.ords_url}/starter/module/$${request.path[pathname]}"
        elif params['language'] == "java" and params['java_framework'] == "tomcat":
            app_url = "http://${local.ci_private_ip}:8080/starter-1.0/$${request.path[pathname]}"
        else:
            app_url = "http://${local.ci_private_ip}:8080/$${request.path[pathname]}"

        if 'apigw_ocid' in params:
            cp_terraform("apigw_existing.tf", "apigw_ci_append.tf")
            inplace_replace('##APP_URL##', app_url,
                            "src/terraform/apigw_existing.tf")
        else:
            cp_terraform("apigw.tf", "apigw_ci_append.tf")
            inplace_replace('##APP_URL##', app_url, "src/terraform/apigw.tf")

# -- Bastion -----------------------------------------------------------------

if 'bastion_ocid' in params:
    cp_terraform("bastion_existing.tf")
else:
    cp_terraform("bastion.tf")

# -- Database ----------------------------------------------------------------

print( "XXXX database="+params.get('database'))


if params.get('database') != "none":
    cp_terraform("output.tf")
    os.mkdir("src/db")

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

if os.path.exists("src/app/oracle.sql"):
    shutil.move("src/app/oracle.sql", "src/db")

# -- Common ------------------------------------------------------------------

print( "XXXX a_common="+" ".join(a_common))

if "autonomous" in a_common:
    if 'atp_ocid' in params:
        cp_terraform("atp_existing.tf")
    else:
        cp_terraform("atp.tf")

if "database" in a_common:
    if 'db_ocid' in params:
        cp_terraform("dbsystem_existing.tf")
    else:
        cp_terraform("dbsystem.tf")

if "mysql" in a_common:
    if 'mysql_ocid' in params:
        cp_terraform("mysql_existing.tf")
    else:
        cp_terraform("mysql.tf")

if 'oke' in a_common:
    if 'oke_ocid' in params:
        cp_terraform("oke_existing.tf", "oke_append.tf")
    else:
        cp_terraform("oke.tf", "oke_append.tf")
        shutil.copy2("../option/oke/oke_destroy.sh", "bin")

if 'fnapp' in a_common:
    if 'fnapp_ocid' in params:
        cp_terraform("function_existing.tf")
    else:
        cp_terraform("function.tf")

if 'apigw' in a_common:
    if 'apigw_ocid' in params:
        cp_terraform("apigw_existing.tf")
    else:
        cp_terraform("apigw.tf")

if 'common' in params:
    shutil.rmtree("src/db")
    shutil.rmtree("src/ui")
    # gather all files
    allfiles = os.listdir('.')
    # Create a common directory
    os.mkdir('common')
    # iterate on all files to move them to 'common'
    for f in allfiles:
        os.rename(f, os.path.join('common', f))

# -- Done --------------------------------------------------------------------
title("Done")
print("Directory "+OUTPUT_DIR+" created.")

# -- Post Creation -----------------------------------------------------------

if mode == GIT:
    print("GIT mode currently not implemented.")
    # git config --local user.email "test@example.com"
    # git config --local user.name "${OCI_USERNAME}"
    # git add .
    # git commit -m "added latest files"
    # git push origin main

elif mode == ZIP:
    # The goal is to have a file that when uncompressed create a directory prefix.
    os.chdir("..")
    os.mkdir("zip/"+OUTPUT_DIR)
    shutil.move(OUTPUT_DIR, "zip/"+OUTPUT_DIR+"/"+params['prefix'])
    os.chdir("zip/"+OUTPUT_DIR)
    shutil.make_archive(OUTPUT_DIR+".zip", format='zip',
                        root_dir='.', base_dir=params['prefix'])

else:
    print()
    readme="README.md"
    if 'common' in params:
        readme="common/README.md" 
    with open(readme, 'r') as fin:
        print(fin.read())
