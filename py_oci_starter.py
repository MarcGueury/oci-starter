#!/usr/bin/env python3
# OCI Starter
# 
# Script to create an OCI deployment scaffold with application source code
# 
# Authors: Marc Gueury & Ewan Slater
# Date: 2022-11-24
import sys, os

# constants
ABORT='ABORT'
GIT='GIT'
CLI='CLI'

# functions
def title():
    s = "-- " + script_name() + " "
    return s.ljust(78,'-')

def script_name():
    return os.path.basename(__file__)

def get_mode():
    n_args=len(sys.argv)
    if n_args < 4:
        return ABORT
    elif n_args == 4:
        return GIT
    else:
        return CLI

def prog_arg_array():
    arr = sys.argv.copy()
    arr.pop(0)
    return arr

mandatory_options = ['-language','-deploy','-db_password']
default_options = {
    'prefix': 'starter',
    'java_framework': 'helidon',
    'java_vm': 'jdk',
    'java_version': 17,
    'kubernetes': 'oke',
    'ui': 'html',
    'database': 'atp',
    'db_user': 'admin'
}

def help():
    return f'''
Usage: {script_name()} [OPTIONS]

oci-starter.sh
   -prefix (default starter)
   -compartment_ocid (default tenancy_ocid)
   -language (mandatory) java | node | python | dotnet | ords 
   -deploy (mandatory) compute | kubernetes | function
   -java_framework (default helidon | springboot | tomcat)
   -java_runtime (default jdk | graalvm)  
   -java_version (default 17 | 11 | 8)
   -kubernetes (default oke | docker) 
   -oke_ocid ()
   -ui (default html | reactjs | jet | angular | none) 
   -vcn_ocid()
   -subnet_ocid()
   -database (default atp | dbsystem | mysql)
   -atp_ocid (optional)
   -db_ocid (optional)
   -mysql_ocid (optional)
   -db_user (default admin)
   -db_password ( mandatory )
'''

def get_params():
    if mode == GIT:
        return git_mode_params()
    if mode == CLI:
        return cli_mode_params()


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

def unknown_parameters(supplied_params, known_params):
    supplied_set = set(supplied_params)
    known_set = set(known_params)
    for known in known_set:
        supplied_set.discard(known)
    return list(supplied_set)

def cli_mode_params():
    return deprefix_keys(list_to_dict(prog_arg_array()))

def git_mode_params():
    keys = ['git_url', 'repository_name', 'oci_username']
    values = prog_arg_array()
    return dict(zip(keys, values))

# the script
print(title())

script_dir=os.getcwd()

mode = get_mode()

if mode == ABORT:
    print(help())
    exit()

params = get_params()

print(f'default_options: {default_options}')
print(missing_parameters(['d','b','c'],['a','b','c']))
print(unknown_parameters(['d','b','c'],['a','b','c']))
print("That's all Folks!")