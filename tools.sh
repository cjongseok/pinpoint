#!/bin/bash

# Why Bash?
#  Powerfull
#  Many tools developed over 40 years
#  Anything on Linux can be dealt with by MASHING UP tools
#
# Why it is needed?
#  So many tools make scripting complex
#  So many syntaxes make scripting complex
#  Kind of facade for easy and fast scripting is needed
#
# CONVENTION or RULE?
#  every arguments should be enveloped by double quotation.
#  Every script should start with set -u
#
# TODO
#  Groups functions as package deliminated by /
#  Vim plugin supporting intellisense for the package
#  Document and example in above of the function are essential 
#
# Return
#  0: normal
#  255

set -u
TRUE="true"
FALSE="false"
SUCCESS=0

LINUX_TYPE="$(cat /etc/os-release | grep "ID_LIKE" | sed -e 's/ID_LIKE=\(.*\)/\1/g' -e 's/"//g')"

function tool_run_as_root(){
    if [ "$EUID" -ne 0 ]; then
        echo "run as root"
        exit
    fi  
}

# $1: binary name
function tool_get_binary_path(){
    local bin_name=$1
    if [ ! -z $(which $bin_name) ]; then
        echo "$(which $bin_name)"

    elif [ ! -z $(which /usr/local/bin/$bin_name) ]; then
        echo "/usr/local/bin/$bin_name"
    fi
}

### PKG Tools ###
# $1 bin name
# $2 pkg name
function tool_install_pkg_if_not_exists(){
    local bin=$1
    local pkg=$2
    if [ -z $(tool_get_binary_path $bin) ]; then
        case "$LINUX_TYPE" in
            "rhel fedora")
                #func_run_as_root
                sudo yum -y install $pkg 2>&1 > /dev/null
                ;;
            "debian")
                #func_run_as_root
                sudo apt-get -y install $pkg 2>&1 /dev/null
                ;;
            *)
                "$LINUX_TYPE is NOT supported"
                exit 1
                ;;
        esac
    fi
}

# $1 bin name
# $2 pkg name
function tool_install_pip_pkg_if_not_exists(){
    bin=$1
    pkg=$2
    if [ -z $(tool_get_binary_path $bin) ]; then
        #func_run_as_root
        sudo pip install $pkg
    fi
}

### GIT Tools ###
# $1: git repository url
# $2: target directory to clone the repository
# $3: (Optional) brnach to checkout
# @description: It does NOT make sure the version is up-to-date, if the git repo
#  already exists.
function tool_git_clone(){
    local url=$1
    local target=$2
    local branch=$3

    if [ -z $url ]; then
        echo "No Git repository url provided"
        exit 1
    fi

    if [ -z $target ]; then
        echo "No target directory for Git clone is provided"
        exit 1
    fi

    tool_install_pkg_if_not_exists git git

    git clone $url $target

    if [ ! -z $branch ]; then
        cd $target
        git checkout $branch
        cd -
    fi
}

### DOCKER Tools ###
# $1: env variable name
# $2: env variable value
# $3: docker-compose file path
function tool_update_env_var_in_docker_compose(){
    name=$1
    value=$2
    docker_compose=$3

    sed -i 's/^\( *- *'"$name"'\).*/\1='"$value"'/g' $docker_compose
}


# $1: Path of docker-compose.yml
function tool_up_docker_compose(){
    local docker_compose_file=$1
#    echo "docker_compose_file=$docker_compose_file"
    local docker_compose_dir=$(dirname $docker_compose_file)

    if [ -z $docker_compose_file ]; then
        echo "No docker-compose file"
        exit
    fi

    tool_install_pip_pkg_if_not_exists docker-compose docker-compose
    local DOCKER_COMPOSE=$(tool_get_binary_path docker-compose)
    echo "DOCKER_COMPOSE=$DOCKER_COMPOSE"
    cd $docker_compose_dir
    sudo $DOCKER_COMPOSE up -d
    cd -
}

# $1: Array of docker-compos.yml paths
function tool_up_docker_composes(){
    local docker_compose_files=("$@")
    local filenum=${#docker_compose_files[@]}
    local unset index

    for ((index=0; index<filenum; index++)); do
        tool_up_docker_compose ${docker_compose_file[index]}
    done

}

#TODO: implement below functions
#function tool_set_env(){}
#function tool_set_envs(){}


### JSON Tools ###
# $1: json file file
# @return: key value list?
#  if the syntax is NOT matched, return nothing
function tool_json_get_obj(){
    local jsonfile=$1
    echo $(jq '.' $jsonfile)
}

# $1: json obj
# $2: json field name
# @return: if the value is null, return nothing
function tool_json_get_obj_value(){
    local json_obj=$1
    local json_field="$2"
    local val=$(echo "$json_obj" | jq '.'$json_field'')
    if ! [[ $val == "null" ]]; then
        echo "$val"
    fi
}

# $1: json array obj
# $2: array index
# @return: json object specified by the index
#  if the index is out of bound, return nothing.
function tool_json_array_index_of(){
    local json_arr=$1
    local arr_index=$2
    #echo "arr_index=$arr_index"
    echo $(echo $json_arr | jq '.['$arr_index']')
}

# $1: json array obj
function tool_json_array_length(){
    local json_arr=$1
#    echo "json_arr=$json_arr"
    #echo $(echo "$json_arr" | jq '. | length')
    echo "$json_arr" | jq '.|length'
}


# $1: cmd
# $2: json key
function tool_json_run_cmd_and_get_val(){
    local cmd=$1
    local json_key=$2
    local json_val=$($cmd | jq '.'$json_key'')
    if [ $? -eq 0 ]; then
        echo $json_val
    else
        return 255
    fi
}


### AWS Tools ###
AWS_EC2_INSTANCE_STATUS_PENDING=0
AWS_EC2_INSTANCE_STATUS_RUNNING=16
AWS_EC2_INSTANCE_STATUS_SUTTING_DOWN=32
AWS_EC2_INSTANCE_STATUS_TERMINATED=48
AWS_EC2_INSTANCE_STATUS_STOPPING=64
AWS_EC2_INSTANCE_STATUS_STOPPED=80
AWS_EC2_INSTANCE_STATUS_NO_INSTANCE=255

# @return: $TRUE or $FALSE
function tool_aws_cli_is_configured(){
    # install aws-cli
    tool_install_pip_pkg_if_not_exists "aws" "awscli"

    # check access_key, secret_key, and and region configured
    local tail_size=$(( $(aws configure list | wc -l)-2 ))
    local aws_conf_list="$(aws configure list | tail -n $tail_size)"
    #local aws_conf_list="$(aws configure list | tail -n $(( $(aws configure list | wc -l) - 2)) )"
    local access_key_type=$(echo "$aws_conf_list" | grep -i access_key | awk '{print $2}')
    local secret_key_type=$(echo "$aws_conf_list" | grep -i secret_key | awk '{print $2}')
    local region_type=$(echo "$aws_conf_list" | grep -i region | awk '{print $2}')

    if [[ "<not" == "$access_key_type" ]] || [[ "<not" == "$secret_key_type" ]] || [[ "<not" == "$region_type" ]]; then
        echo $FALSE
    else
        echo $TRUE
    fi
}

# $1: instance_id 
# @return: "RUNNING" "STOPPED" "TERMINATED" ""
function tool_aws_ec2_get_instance_state_code(){
    local instance_id=$1
    local aws_cmd="aws ec2 describe-instance-status --instance-ids $instance_id"
    local json_key="InstanceStatuses[0].InstanceState.Code"
    tool_run_cmd_and_get_json_val "$aws_cmd" "$json_key"
}

# $1: instance_id
function tool_aws_ec2_start_instance(){
    local instance_id=$1
    local aws_cmd="aws ec2 start-instances --instance-ids $instance_id"
    local json_key="InstanceStatuses[0].InstanceState.Code"
    local instance_state=$(tool_run_cmd_and_get_json_val "$aws_cmd" "$json_key")

    if [ $? -eq $SUCCESS ]; then
        echo $instance_state
    else
        return 255
    fi
}

#function tool_aws_ec2_launch_instance(){

    # launch an instance
    # register the caller as authorized host to the new instance
    # register the new instance as known host to the caller
#}

### Ansible Tools ###
# $1: name
# $2: play
#function tool_andible_generate_task(){}

# $1: hosts
# $2: remote_user
# $3: tasks
#function tool_ansible_generate_playbook(){}

# $1: playbook file
# $2: host file
# $3: private-key
# $4: other options
#function tool_ansible_run_playbook(){}

# $1: input string
function tool_escape_characters_for_sed(){
    local input_str=$1
    #local result= "${input_str//\//\\/}"
    
#    result="${result//\"/\\"}"
    #echo $result
    echo "${input_str//\//\\/}"
    #echo "${$(echo ${input_str//\//\\/})//\"/\\"}"
   #echo "${${input_str//\//\\/}//a/A}"
}

# $1: template file
# $2: key
# $3: value
# $4: key
# $5: value
# ...
function tool_template_fill_in_in_place(){
    local template_file=$1
    local argv=($@)
    local argn=$#
    local unset index
    if [ $argn -lt 3 ] || [ $((argn%2)) -ne 1 ]; then
        exit 255
    fi

    local sed_expressions=""
    for ((index=1; index<argn; index=index+2)); do
        local key=${argv[index]}
        local value="${argv[index+1]}"
        key=$(tool_escape_characters_for_sed $key)
        value=$(tool_escape_characters_for_sed $value)
        sed_expressions=$sed_expressions" -e 's/<$key>/$value/g'"
    done

    #eval "cat $template_file | sed $sed_expressions" > $output_file
    eval "sed -i $sed_expressions $template_file"
}


# $1: template file
# $2: output file
# $2: key
# $3: value
# $4: key
# $5: value
# ...
function tool_template_fill_in(){
    local template_file=$1
    local output_file=$2
    local argv=($@)
    local argn=$#
    local unset index
    if [ $argn -lt 4 ] || [ $((argn%2)) -ne 0 ]; then
        exit 255
    fi

    rm $output_file

    local sed_expressions=""
    for ((index=2; index<argn; index=index+2)); do
        local key=${argv[index]}
        local value="${argv[index+1]}"
        sed_expressions=$sed_expressions" -e 's/<$key>/$value/g'"
    done

    eval "cat $template_file | sed $sed_expressions" > $output_file
}

# $1: template file
# $2: output file
# $3: key
# $4: value
function tool_template_fill_in_with_spacing_arg(){
    local template_file=$1
    local output_file=$2
    local key=$3
    local value="$4"

    local sed_expressions="'s/<$key>/$value/g'"

    eval "cat $template_file | sed $sed_expressions" > $output_file
}

# $1: ansible user
# $2: src file
# $3: dest file
# $4: owner
# $5: private key file
# ...: hosts
function tool_ansible_copy_and_run_script_in_sudo(){
    local PLAYBOOK_DIR=$(dirname $(readlink -e $0))/playbook_templates
    local PLAYBOOK_TEMPLATE=$PLAYBOOK_DIR/copy_and_run_script.yml
    local PLAYBOOK_GEN_FILE=$PLAYBOOK_DIR/.playbook.yml
    local HOSTLIST_FILE=$PLAYBOOK_DIR/.ansible_hosts
    local PRV_KEY_FILE=$5

    local ANSIBLE_USER=$1
    local SRC_FILE=$2
    local DEST_FILE=$3
    local OWNER=$4
    local unset index

    ANSIBLE_USER=$(tool_escape_characters_for_sed $ANSIBLE_USER)
    SRC_FILE=$(tool_escape_characters_for_sed $SRC_FILE)
    DEST_FILE=$(tool_escape_characters_for_sed $DEST_FILE)
    OWNER=$(tool_escape_characters_for_sed $OWNER)

    tool_template_fill_in $PLAYBOOK_TEMPLATE $PLAYBOOK_GEN_FILE "ANSIBLE_USER" $ANSIBLE_USER "SRC_FILE" $SRC_FILE "DEST_FILE" $DEST_FILE "OWNER" $OWNER
    #cat $PLAYBOOK_GEN_FILE

    local argv=($@)
    local argn=$#
    if [ -f $HOSTLIST_FILE ]; then
        rm $HOSTLIST_FILE
    fi
    touch $HOSTLIST_FILE
    for ((index=5; index<argn; index++)); do
        local host=${argv[index]}
        echo "$host" >> $HOSTLIST_FILE
    done

    ansible-playbook $PLAYBOOK_GEN_FILE -i $HOSTLIST_FILE --private-key $PRV_KEY_FILE --sudo
}

# $1: ansible user
# $2: private key
# $3: git repository
# $4: git repo dest
# $5: git version
# $6: cmd line
# $7: hosts
function tool_ansible_git_clone_and_run_in_sudo(){
    local PLAYBOOK_DIR=$(dirname $(readlink -e $0))/playbook_templates
    local PLAYBOOK_TEMPLATE=$PLAYBOOK_DIR/git_clone_and_run_script.yml
    local PLAYBOOK_GEN_FILE=$PLAYBOOK_DIR/.playbook.yml
    local HOSTLIST_FILE=$PLAYBOOK_DIR/.ansible_hosts
    local PRV_KEY_FILE=$2

    local ansible_user=$1
    local git_repo=$3
    local dest_repo=$4
    local repo_version=$5
    local cmd_line=$6
    local hosts="$7"
    local unset index

    ansible_user=$(tool_escape_characters_for_sed $ansible_user)
    git_repo=$(tool_escape_characters_for_sed $git_repo)
    dest_repo=$(tool_escape_characters_for_sed $dest_repo)
    repo_version=$(tool_escape_characters_for_sed $repo_version)
    cmd_line=$(tool_escape_characters_for_sed "$cmd_line")

#    echo "ansible_user=$ansible_user"
#    echo "git_repo=$git_repo"
#    echo "dest_repo=$dest_repo"
#    echo "repo_version=$repo_version"

#    tool_template_fill_in $PLAYBOOK_TEMPLATE $PLAYBOOK_GEN_FILE "CMD_LINE" "$cmd_line" "ANSIBLE_USER" $ansible_user "GIT_REPO" $git_repo "DEST_REPO" $dest_repo "REPO_VERSION" $repo_version
    #tool_template_fill_in $PLAYBOOK_TEMPLATE $PLAYBOOK_GEN_FILE "ANSIBLE_USER" $ansible_user "GIT_REPO" $git_repo "DEST_REPO" $dest_repo "REPO_VERSION" $repo_version "CMD_LINE" "$cmd_line"
    tool_template_fill_in $PLAYBOOK_TEMPLATE $PLAYBOOK_GEN_FILE.tmp "ANSIBLE_USER" $ansible_user "GIT_REPO" $git_repo "DEST_REPO" $dest_repo "REPO_VERSION" $repo_version 
    tool_template_fill_in_with_spacing_arg $PLAYBOOK_GEN_FILE.tmp $PLAYBOOK_GEN_FILE "CMD_LINE" "$cmd_line"
    
    local argv=($@)
    local argn=$#
    if [ -f $HOSTLIST_FILE ]; then
        rm -f $HOSTLIST_FILE
    fi
    touch $HOSTLIST_FILE
    for host in $(echo $hosts); do
    #for ((index=6; index<argn; index++)); do
     #   local host=${argv[index]}
        echo "$host" >> $HOSTLIST_FILE
    done

    echo "ansible-playbook $PLAYBOOK_GEN_FILE -vvvv -i $HOSTLIST_FILE --private-key $PRV_KEY_FILE --sudo"
    ansible-playbook $PLAYBOOK_GEN_FILE -vvvv -i $HOSTLIST_FILE --private-key $PRV_KEY_FILE --sudo
}


### SSH Tools ###
# $1: <user_name>@<host>
# $2: commands
#function tool_ssh_cmd(){
    
#}

# $1: <user_name>@<host>
# $2: commands
# $3: sudo passwd (, if needed)
#function tool_ssh_sudo_cmd(){}

#function tool_ssh_deliver_file(){}










