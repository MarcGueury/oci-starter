#!/usr/bin/env python3
# OCI Starter
# 
# Script to create an OCI deployment scaffold with application source code
# 
# Authors: Marc Gueury & Ewan Slater
# Date: 2022-11-24
import sys, os, shutil, json
from datetime import datetime

# constants
ABORT='ABORT'
GIT='git'
CLI='cli'
ZIP='zip'
EXISTING='existing'
NEW='new'
TO_FILL="__TO_FILL__"
OUTPUT_DIR = os.getenv('REPOSITORY_NAME')
BASIS_DIR = "basis"

# functions
def title():
    s = "-- " + script_name() + " "
    return s.ljust(78,'-')

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
    CLI: ['-language','-deploy','-db_password']
}

def mandatory_options(mode):
    return MANDATORY_OPTIONS[mode]

default_options = {
    '-prefix': 'starter',
    '-java_framework': 'springboot',
    '-java_vm': 'jdk',
    '-java_version': '17',
    '-kubernetes': 'oke',
    '-ui': 'html',
    '-database': 'atp',
    '-license': 'included',
    '-vcn_strategy': NEW,
    '-mode': CLI
}

no_default_options = ['-compartment_ocid', '-oke_ocid', '-vcn_ocid', \
    '-atp_ocid', '-db_ocid', '-pdb_ocid', '-mysql_ocid', '-db_user', \
    '-fnapp_ocid', '-apigw_ocid', '-bastion_ocid', '-auth_token', \
    '-subnet_ocid', '-infra_as_code' ]

# hidden_options - allowed but not advertised
hidden_options = ['-zip', '-infra-as-code']

def allowed_options():
    return list(default_options.keys()) + hidden_options \
        + mandatory_options(mode) + no_default_options

allowed_values = {
    '-language': {'java','node','python','dotnet','go','ords'},
    '-deploy': {'compute','kubernetes','function','container_instance','ci'},
    '-java_framework': {'springboot','helidon','tomcat','micronaut'},
    '-java_vm': {'jdk','graalvm','graalvm_native'},
    '-java_version': {'8', '11', '17'},
    '-kubernetes':{'oke','docker'},
    '-ui': {'html','jet','angular','reactjs','none'},
    '-database': {'atp','database','pluggable','mysql','none'},
    '-license': {'included','LICENSE_INCLUDED','byol','BRING_YOUR_OWN_LICENSE'},
    '-infra_as_code': {'terraform_local','terraform_object_storage','resource_manager'},
    '-mode': {CLI,GIT,ZIP}
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
        'kubernetes': 'TF_VAR_kubernetes_strategy',
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
    params['database'] = longhand('database', {'atp': 'autonomous', 'dbsystem': 'database'})
    params['db_existing_strategy'] = NEW
    db_deps = {'db_ocid': 'database', 'atp_ocid': 'autonomous', 'pdb_ocid': 'pluggable', 'mysql_ocid':'mysql'}
    for dep in db_deps:
        if params.get(dep) is not None:
            params['db_existing_strategy'] = EXISTING
        elif params.get('database') == params.get(db_deps[dep]) and params.get('db_existing_strategy') == EXISTING:
            error(f"-{dep} required if db_existing_strategy is existing")
    if params.get('database') != 'autonomous' and params.get('language') == 'ords':
        error(f'OCI starter only supports ORDS on ATP (Autonomous)')
    if params.get('database') == 'pluggable':
        if (params.get('db_ocid') is not None):
            params['db_existing_strategy'] = NEW
        if (params.get('db_ocid') is None and params.get('pdb_ocid') is None):
          error(f'Plugglable Database needs an existing DB_OCID or PDB_OCID')
    if params.get('db_user') == None:
        default_users = {'autonomous':'admin', 'database':'system', 'pluggable':'system',  'mysql':'root'}
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
    params['deploy'] = longhand('deploy',{'oke':'kubernetes', 'ci':'container_instance'})
    if params.get('oke_ocid') is not None:
       params['oke_strategy'] = EXISTING
    if params.get('deploy') == 'kubernetes':
        if params.get('kubernetes') == 'docker':
            params['kubernetes'] = 'Docker image only'
        else:
            params['kubernetes'] = 'OKE'
            if params.get('oke_strategy') == None:
               params['oke_strategy'] = NEW

def vcn_rules():
    if 'vcn_ocid' in params:
        params['vcn_strategy'] = EXISTING
    elif 'subnet_ocid' in params:
        error('-vcn_ocid required for -subnet_ocid')

def ui_rules():
    params['ui'] = longhand('ui', {'reactjs':'ReactJS','none':'None'})

def auth_token_rules():
    if params.get('deploy') != 'compute' and params.get('auth_token') is None:
        warning('-auth_token is not set. Will need to be set in env.sh')
        params['auth_token'] = TO_FILL

def compartment_rules():
    if params.get('compartment_ocid') is None:
        warning('-compartment_ocid is not set. Components will be created in root compartment. Shame on you!')

def license_rules():
    license_model = os.getenv('LICENSE_MODEL')
    if license_model is not None:
       params['license'] = license_model
    params['license'] = longhand('license', {'included': 'LICENSE_INCLUDED','byol': 'BRING_YOUR_OWN_LICENSE'})

def zip_rules():
    if 'zip' in params:
       OUTPUT_DIR = params['zip']
       del params['zip']
       file_output( 'zip' + os.sep + OUTPUT_DIR + '.param', [json.dumps(params)])

def apply_rules():
    language_rules()
    kubernetes_rules()
    ui_rules()
    db_rules()
    vcn_rules()
    auth_token_rules()
    compartment_rules()
    license_rules()
    zip_rules()

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

def deprefix_keys(a_dict, prefix_length = 1):
    return dict(map(lambda x: (x[0][prefix_length:],x[1]),a_dict.items()))

def missing_parameters(supplied_params, expected_params):
    expected_set = set(expected_params)
    supplied_set = set(supplied_params)
    for supplied in supplied_set:
        expected_set.discard(supplied)
    return list(expected_set)

def get_params():
    return deprefix_keys( {**default_options, **prog_arg_dict()} )

def git_params():
    keys = ['git_url', 'repository_name', 'oci_username']
    values = prog_arg_list()
    return dict(zip(keys, values))

def readme_contents():
    contents = ['''## OCI-Starter
### Usage 

### Commands
- build.sh      : Build the whole program: Run Terraform, Configure the DB, Build the App, Build the UI
- destroy.sh    : Destroy the objects created by Terraform
- env.sh        : Contains the settings of your project

### Directories
- src           : Sources files
  - app         : Source of the Backend Application (Command: build_app.sh)
  - ui          : Source of the User Interface (Command: build_ui.sh)
  - db          : SQL files of the database
  - terraform   : Terraform scripts (Command: plan.sh / apply.sh)'''
    ]
    if params['deploy'] == 'compute':
        contents.append("  - compute     : Contains the deployment files to Compute")
    elif params['deploy'] == 'kubernetes':
        contents.append("  - oke         : Contains the deployment files to Kubernetes")
    contents.append('\n### Next Steps:')
    if TO_FILL in params.values():
        contents.append("- Edit the file env.sh. Some variables need to be filled:")
        for param, value in params.items():
            if value == TO_FILL:
                contents.append(f'export {get_tf_var(param)}="{params[param]}"')
    contents.append("\n- Run:")
    if mode == CLI:
        contents.append("  cd output")
    contents.append("  ./build.sh")
    return contents

def env_sh_contents():
    del params['mode']
    timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M-%S-%f")
    contents = ['#!/bin/bash']
    contents.append('SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )')
    contents.append(f'export OCI_STARTER_CREATION_DATE={timestamp}')
    contents.append(f'export OCI_STARTER_VERSION=1.3')
    contents.append('')
    contents.append('# Env Variables')
    if params.get('compartment_ocid') == None:
        contents.append('# export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx')
    for param in params:
        var_comment = get_tf_var_comment(contents, param)
        contents.append(f'export {get_tf_var(param)}="{params[param]}"')
    contents.append('')
    contents.append('# Get other env variables automatically (-silent flag can be passed)')
    contents.append('. $SCRIPT_DIR/bin/auto_env.sh $1')
    return contents

def get_tf_var_comment(contents, param):
    comments = {
        'auth_token': ['See doc: https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrygettingauthtoken.htm'],
        'db_password': ['Requires at least 12 characters, 2 letters in lowercase, 2 in uppercase, 2 numbers, 2 special characters. Ex: LiveLab__12345','If not filled, it will be generated randomly during the first build.'],
        'license': ['BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED']
    }.get(param)
    if comments is not None:
       for comment in comments:
          contents.append(f'# {get_tf_var(param)} : {comment}')

def write_env_sh(output_dir = OUTPUT_DIR):
    output_path = output_dir + os.sep + 'env.sh'
    file_output(output_path, env_sh_contents())
    os.chmod(output_path, 0o755)

def write_readme(output_dir = OUTPUT_DIR):
    output_path = output_dir + os.sep + 'README.md'
    file_output(output_path, readme_contents())

def file_output(file_path, contents):
    output_file = open(file_path, "w")
    output_file.writelines('%s\n' % line for line in contents)
    output_file.close()

def copy_basis(basis_dir = BASIS_DIR, output_dir = OUTPUT_DIR):
    shutil.copytree(basis_dir, output_dir)

# the script
print(title())

script_dir=os.getcwd()

params = get_params()
mode = get_mode()
unknown_params = missing_parameters(allowed_options(), prog_arg_dict().keys())
illegal_params = check_values()
missing_params = missing_parameters(prog_arg_dict().keys(), mandatory_options(mode))
if len(unknown_params) > 0 or len(illegal_params) > 0 or len(missing_params) > 0:
    mode = ABORT

warnings=[]
errors=[]

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
    exit()

if mode == ABORT:
    print(help())
    exit()

print(f'Mode: {mode}')
print(f'params: {params}')
print("That's all Folks!")
print(title())