#!/bin/bash

# Setup variables
GITHUB_LINK="https://raw.githubusercontent.com/rootorchild/butdr/master"
BIN_DIR="${HOME}/bin"
CONF_DIR="${HOME}/.config"
ACCT_DIR="${CONF_DIR}/accounts"
BUTDR_CONF="${CONF_DIR}/butdr.conf"
RCLONE_CONF="${HOME}/.config/rclone/rclone.conf"
DF_BACKUP_DIR="${HOME}/backup"
DF_TAR_BEFORE_UPLOAD="No"
DF_SYNC_FILE="No"
DF_LOG_FILE="${CONF_DIR}/butdr.log"
DF_DAY_REMOVE="7"
DF_DRIVE_FOLDER_ID="None"
DF_EMAIL_USER="None"
DF_EMAIL_PASS="None"
DF_EMAIL_TO="None"
RCLONE_BIN="${BIN_DIR}/rclone"
CRON_BACKUP="${BIN_DIR}/cron_backup.bash"
SETUP_FILE="${BIN_DIR}/butdr.bash"
CRON_TEMP="${CONF_DIR}/old_cron"
FIRST_OPTION=$1
SECOND_OPTION=$2

# Date variables
TODAY=`date +"%d_%m_%Y"`

# Color variables
GREEN='\e[32m'
RED='\e[31m'
YELLOW='\e[33m'
REMOVE='\e[0m'

# Detect error
detect_error(){
    if [ $? -ne 0 ]
    then
        show_write_log "`change_color red $2` $3. Exit"
        exit 1
    else
        show_write_log "$1"
    fi
}

# Change color of words
change_color(){
    case $1 in
         green) echo -e "${GREEN}$2${REMOVE}";;
           red) echo -e "${RED}$2${REMOVE}";;
        yellow) echo -e "${YELLOW}$2${REMOVE}";;
             *) echo "$2";;
    esac
}

# Check option
check_option(){
    # Check option is number
    if [ "$1" == number ]
    then
        if [ -z "$2" ]
        then
            echo "Please choose from 1 to $2"
            return 1
        else
            TRAP=`echo $2 | tr -d "[:digit:]"`
            if [ -z "${TRAP}" ]
            then
                if [[ $2 -lt 1 ]] || [[ $2 -gt $3 ]]
                then
                    echo "Please choose from 1 to $2"
                    return 1
                else
                    return 0
                fi
            else
                echo "Please choose from 1 to $2"
                return 1
            fi
        fi
    fi
    # Check option in a list
    if [ "$1" == list ]
    then
        if [ -z $2 ]
        then
            echo -e "${RED}Missing command${REMOVE}"
            return 1
        fi
        VALUE=\\b$2\\b
        List=($3)
        if [[ ${List[*]} =~ ${VALUE} ]]
        then
            return 0
        else
            echo -e "${RED}No such command ${SECOND_OPTION}${REMOVE}"
            return 1
        fi
    fi
}

# Check MD5 of downloaded file
check_md5sum(){
    curl -s -o $2 ${GITHUB_LINK}/$1
    ORIGIN_MD5=`curl -s ${GITHUB_LINK}/MD5SUM | grep $1 | awk '{print $1}'`
    LOCAL_MD5=`md5sum $2 | awk '{print $1}'`
    if [ "${ORIGIN_MD5}" == "${LOCAL_MD5}" ]
    then
        show_write_log "Check md5sum for file $1 successful"
    else
        show_write_log "`change_color red [CHECKS][FAIL]` Can not verify md5 for file $1. Exit!"
        exit 1
    fi
}

# Check log file
check_log_file(){    
    if [ ! -f ${BUTDR_CONF} ]
    then
        LOG_FILE=${DF_LOG_FILE}        
    else
        LOG_FILE=`cat ${BUTDR_CONF} | grep "^LOG_FILE" | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        if [ "${LOG_FILE}" == "" ]
        then
            LOG_FILE=${DF_LOG_FILE}
        fi
    fi
    create_dir .config
    create_dir .config/accounts
    create_dir bin
}

# Write log
show_write_log(){
    echo "`date '+[ %d/%m/%Y %H:%M:%S ]'` $1" | tee -a ${LOG_FILE}
}

# Create necessary directory
create_dir(){
    if [ ! -d ${HOME}/$1 ]
    then
        mkdir -p ${HOME}/$1
        if [ ! -d ${HOME}/$1 ]
        then
            echo "Can not create directory ${HOME}/$1. Exit"
            exit 1
        else
            if [ "$1" == ".config" ]
            then
                show_write_log "---"
                show_write_log "Creating necessary directory..."
            fi
            show_write_log "Create directory ${HOME}/$1 successful"
        fi
    else
        if [ "$1" == ".config" ]
        then
            show_write_log "---"
            show_write_log "Creating necessary directory..."
        fi
        show_write_log "Directory ${HOME}/$1 existed. Skip"
    fi
    echo 1 >> ${HOME}/$1/test.txt
    detect_error "Check write to ${HOME}/$1 successful" "[CHECK][FAIL]" "Can not write to ${HOME}/$1"
    rm -f ${HOME}/$1/test.txt
}

# Check pre-install package
check_package(){
    which $1 >/dev/null
    if [ $? -ne 0 ]
    then
        show_write_log "Command $1 not found. Trying to install $1..."
        sleep 3
        ${INSTALL_CM} install -y $1
        which $1 >/dev/null
        if [ $? -ne 0 ]
        then
            show_write_log "Can not install $1 package. Please install $1 manually."
            exit 1
        fi
        detect_error "Package $1 is installed" "[CHECK][FAIL]" "Can not install $1 package. Please install $1 manually"
    else
        show_write_log "Package $1 is installed"
    fi
}

# Write config
write_config(){
    if [ "$4" == "" ]
    then
        VALUE=$3
    else
        VALUE=$4
    fi
    VAR=$2
    eval "$VAR"="$VALUE"
    if [ -f $1 ]
    then
        CHECK_VALUE=`cat $1 | grep -c "^$2="`
        if [ ${CHECK_VALUE} -eq 1 ]
        then
            VALUE=`echo "${VALUE}" | sed 's/\//\\\\\//g'`
            sed -i "s/$2=.*/$2=$VALUE/" $1
        else
            echo "$2=$VALUE" >> $1
        fi
    else
        echo "$2=$VALUE" >> $1
    fi
}

# Detect OS
detect_os(){
    show_write_log "Checking OS..."
    if [ -f /etc/os-release ]
    then
        OS=`cat /etc/os-release | grep "^NAME=" | cut -d'"' -f2 | awk '{print $1}'`
        if [[ "${OS}" == "CentOS" ]] || [[ "${OS}" == "CloudLinux" ]]
        then
            INSTALL_CM="yum"
        elif [[ "${OS}" == "Ubuntu" ]] || [[ "${OS}" == "Debian" ]]
        then
            INSTALL_CM="apt"
        elif [[ "${OS}" == "openSUSE" ]] || [[ "${OS}" == "SLES" ]]
        then
            INSTALL_CM="zypper"
        else
            show_write_log "Sorry! We do not support your OS. Exit"
            exit 1
        fi
    else
        show_write_log "Sorry! We do not support your OS. Exit"
        exit 1
    fi
    show_write_log "OS supported"
    show_write_log "Checking necessary package..."
    check_package curl
    check_package unzip
}

# Check network
check_network(){
    show_write_log "Cheking network..."
    curl -sI raw.githubusercontent.com >/dev/null
    detect_error "Connect Github successful" "[CHECKS][FAIL]" "Can not connect to Github file, please check your network. Exit"
    if [ "${FIRST_OPTION}" != "--update" ]
    then
        curl -sI https://downloads.rclone.org >/dev/null
        detect_error "Connect rclone successful" "[CHECKS][FAIL]" "Can not connect to rclone file, please check your network. Exit"
    fi
}

# Download file from Github
download_file(){
    show_write_log "Downloading script cron_backup from github..."
    check_md5sum cron_backup.bash "${CRON_BACKUP}"
    show_write_log "Downloading script butdr from github..."
    check_md5sum butdr.bash "${SETUP_FILE}"
    chmod 755 ${SETUP_FILE} ${CRON_BACKUP}
}

# Download rclone
download_rclone(){
    show_write_log "Downloading rclone from homepage..."
    cd $HOME/bin
    curl -o rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip
    detect_error "Download rclone successful" "[DOWNLOAD][FAIL]" "Can not download rclone, please check your network. Exit"
    unzip -q rclone.zip -d rclone-butdr
    mv rclone-butdr/rclone-*-linux-amd64/rclone rclone
    rm -rf rclone.zip rclone-butdr
}

# Setup Google drive account
setup_drive(){
    echo ""
    echo "Read more: https://github.com/mbrother2/backuptogoogle/wiki/Create-own-Google-credential-step-by-step"
    read -p " Your Google API client_id: " DRIVE_CLIENT_ID
    read -p " Your Google API client_secret: " DRIVE_CLIENT_SECRET
    echo ""
    echo "Read more https://github.com/mbrother2/backuptogoogle/wiki/Get-Google-folder-ID"
    read -p " Your Google folder ID: " DRIVE_FOLDER_ID
    if [[ -z ${DRIVE_CLIENT_ID} ]] || [[ -z ${DRIVE_CLIENT_SECRET} ]]
    then
        if [ -z ${DRIVE_FOLDER_ID} ]
        then
            ${RCLONE_BIN} config create googledrive drive config_is_local false scope drive
        else
            ${RCLONE_BIN} config create googledrive drive config_is_local false scope drive root_folder_id ${DRIVE_FOLDER_ID}
        fi
    else
        if [ -z ${DRIVE_FOLDER_ID} ]
        then
            ${RCLONE_BIN} config create googledrive drive config_is_local false scope drive client_id ${DRIVE_CLIENT_ID} client_secret ${DRIVE_CLIENT_SECRET}
        else
            ${RCLONE_BIN} config create googledrive drive config_is_local false scope drive client_id ${DRIVE_CLIENT_ID} client_secret ${DRIVE_CLIENT_SECRET} root_folder_id ${DRIVE_FOLDER_ID}
        fi
    fi
    write_config "${ACCT_DIR}/googledrive.conf" DRIVE_FOLDER_ID  "${DF_DRIVE_FOLDER_ID}"  "${DRIVE_FOLDER_ID}"
}

# Create config for Google drive account
create_config(){
    echo ""
    read -p " Which directory on your server do you want to upload to account $1?(default ${DF_BACKUP_DIR}): " BACKUP_DIR
    read -p " How many days do you want to keep backup on Google Drive?(default ${DF_DAY_REMOVE}): " DAY_REMOVE
    echo ""
    echo "Read more https://github.com/mbrother2/backuptogoogle/wiki/What-is-the-option-SYNC_FILE%3F"
    read -p " Do you want only sync file(default no)(y/n): " SYNC_FILE
    DRIVE_FOLDER_ID=`cat ${ACCT_DIR}/$1.conf | grep "^DRIVE_FOLDER_ID=" | cut -d"=" -f2`
    if [[ -z ${DRIVE_FOLDER_ID} ]] || [[ "${FIRST_OPTION}" == "--config" ]]
    then
        echo ""
        echo "Read more https://github.com/mbrother2/backuptogoogle/wiki/Get-Google-folder-ID"
        if [ "${SYNC_FILE}" == "y" ]
        then
            echo "Because you choose sync file method, so you must enter exactly Google folder ID here!"
        fi
        read -p " Your Google folder ID(default ${DF_DRIVE_FOLDER_ID}): " DRIVE_FOLDER_ID
    fi
    if [ "${SYNC_FILE}" == "y" ]
    then
        TAR_BEFORE_UPLOAD=${DF_TAR_BEFORE_UPLOAD}
    else
        read -p " Do you want compress directory before upload?(default no)(y/n): " TAR_BEFORE_UPLOAD
    fi
    if [ "${SYNC_FILE}" == "y" ]
    then
        SYNC_FILE="Yes"
    else
        SYNC_FILE="No"
    fi
    if [ "${TAR_BEFORE_UPLOAD}" == "y" ]
    then
        TAR_BEFORE_UPLOAD="Yes"
    else
        TAR_BEFORE_UPLOAD=${DF_TAR_BEFORE_UPLOAD}
    fi
    write_config "${ACCT_DIR}/$1.conf" BACKUP_DIR        "${DF_BACKUP_DIR}"        "${BACKUP_DIR}"
    write_config "${ACCT_DIR}/$1.conf" DAY_REMOVE        "${DF_DAY_REMOVE}"        "${DAY_REMOVE}"
    write_config "${ACCT_DIR}/$1.conf" DRIVE_FOLDER_ID   "${DF_DRIVE_FOLDER_ID}"   "${DRIVE_FOLDER_ID}"
    write_config "${ACCT_DIR}/$1.conf" SYNC_FILE         "${DF_SYNC_FILE}"         "${SYNC_FILE}"
    write_config "${ACCT_DIR}/$1.conf" TAR_BEFORE_UPLOAD "${DF_TAR_BEFORE_UPLOAD}" "${TAR_BEFORE_UPLOAD}"
    if [ $? -ne 0 ]
    then
        show_write_log "`change_color red [ERROR]` Can not write config to file ${BUTDR_CONF}. Please check permission of this file. Exit"
        exit 1
    else
        if [ ! -d ${BACKUP_DIR} ]
        then
            show_write_log "`change_color yellow [WARNING]` Directory ${BACKUP_DIR} does not exist! Ensure you will be create it after."
            sleep 3
        fi
        show_write_log "Setup config file for account $1 successful"
    fi
    DRIVE_FOLDER_ID=`cat ${ACCT_DIR}/$1.conf | grep "^DRIVE_FOLDER_ID=" | cut -d"=" -f2`
    CHECK_RCLONE_ROOT_FOLDER_ID=`cat ${RCLONE_CONF} | grep -c "^root_folder_id = "`
    if [ "${DRIVE_FOLDER_ID}" == "None" ]
    then
        if [ ${CHECK_RCLONE_ROOT_FOLDER_ID} -ne 0 ]
        then
            sed -i "/^root_folder_id =/d" ${RCLONE_CONF}
        fi
    else
        if [ ${CHECK_RCLONE_ROOT_FOLDER_ID} -eq 0 ]
        then
            sed -i "/^\[googledrive\]$/a root_folder_id = ${DRIVE_FOLDER_ID}" ${RCLONE_CONF}
        else
            sed -i "s/^root_folder_id = .*/root_folder_id = ${DRIVE_FOLDER_ID}/" ${RCLONE_CONF}
        fi
    fi
}

# Setup global config file
config_global(){
    show_write_log "Setting up global config file..."
    echo ""
    echo "Read more https://github.com/mbrother2/backuptogoogle/wiki/Turn-on-2-Step-Verification-&-create-app's-password-for-Google-email"
    read -p " Do you want to send email if upload error(default no)(y/n): " SEND_EMAIL
    if [ "${SEND_EMAIL}" == "y" ]
    then
        read -p " Your Google email user name: " EMAIL_USER
        read -p " Your Google email password: " EMAIL_PASS
        read -p " Which email will be receive notify?: " EMAIL_TO
    fi
    write_config ${BUTDR_CONF} LOG_FILE     "${DF_LOG_FILE}"     "${LOG_FILE}"
    write_config ${BUTDR_CONF} EMAIL_USER   "${DF_EMAIL_USER}"   "${EMAIL_USER}"
    write_config ${BUTDR_CONF} EMAIL_PASS   "${DF_EMAIL_PASS}"   "${EMAIL_PASS}" 
    write_config ${BUTDR_CONF} EMAIL_TO     "${DF_EMAIL_TO}"     "${EMAIL_TO}"
    detect_error "Setup global config file successful" "[ERROR]" "Can not write config to file ${BUTDR_CONF}. Please check permission of this file. Exit"
}

# Setup cron backup
setup_cron(){
    echo ""
    show_write_log "Setting up cron backup..."
    CHECK_BIN=`echo $PATH | grep -c "${HOME}/bin"`
    if [ ${CHECK_BIN} -eq 0 ]
    then
        echo "PATH=$PATH:$HOME/bin" >> ${HOME}/.profile
        echo "export PATH" >> ${HOME}/.profile
        source ${HOME}/.profile
    fi    
    crontab -l > ${CRON_TEMP}
    CHECK_CRON=`cat ${CRON_TEMP} | grep -c "cron_backup.bash"`
    if [ ${CHECK_CRON} -eq 0 ]
    then
        echo "PATH=$PATH" >> ${CRON_TEMP}
        echo "0 0 * * * bash ${CRON_BACKUP} >/dev/null 2>&1" >> ${CRON_TEMP}
        crontab ${CRON_TEMP}
        if [ $? -ne 0 ]
        then
            show_write_log "Can not setup cronjob to backup! Please check again"
            SHOW_CRON="`change_color yellow [WARNING]` Can not setup cronjob to backup"
        else
            show_write_log "Setup cronjob to backup successful"
            SHOW_CRON="0 0 * * * bash ${CRON_BACKUP} >/dev/null 2>&1"
        fi
    else
        show_write_log "Cron backup existed. Skip"
        SHOW_CRON=`cat ${CRON_TEMP} | grep "cron_backup.bash"`
    fi
    rm -f  ${CRON_TEMP}
}

# Reset account
account_reset(){
    rm -f ${RCLONE_CONF}
    show_write_log "Creating googledrive account..."
    setup_drive
}

# Config backup file for single account
config_backup_single(){
    echo ""
    show_write_log "Setting up backup config file..."
    create_config googledrive
}

# Show global config
show_global_config(){
    show_write_log "|---"
    show_write_log "| Your email         : ${EMAIL_USER}"
    show_write_log "| Email password     : ${EMAIL_PASS}"
    show_write_log "| Email notify       : ${EMAIL_TO}"
    show_write_log "| Global config file : ${BUTDR_CONF}"
}

# Show backup config
show_backup_config(){
    CURRENT_ACCOUNT=`ls -1 ${ACCT_DIR} | grep ".conf$" | head -1 | sed 's/.conf//'`
    BACKUP_DIR=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^BACKUP_DIR=" | cut -d"=" -f2`
    DAY_REMOVE=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^DAY_REMOVE=" | cut -d"=" -f2`
    BACKUP_DIR=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^BACKUP_DIR=" | cut -d"=" -f2`
    DRIVE_FOLDER_ID=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^DRIVE_FOLDER_ID=" | cut -d"=" -f2`
    SYNC_FILE=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^SYNC_FILE="  | cut -d"=" -f2`
    TAR_BEFORE_UPLOAD=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^TAR_BEFORE_UPLOAD=" | cut -d"=" -f2`
    show_write_log "|---"
    show_write_log "| Account            : ${CURRENT_ACCOUNT}"
    show_write_log "| Backup dir         : ${BACKUP_DIR}"
    show_write_log "| Keep backup        : ${DAY_REMOVE} days"
    show_write_log "| Google folder ID   : ${DRIVE_FOLDER_ID}"
    show_write_log "| Sync file          : ${SYNC_FILE}"
    show_write_log "| Tar before upload  : ${TAR_BEFORE_UPLOAD}"
}

# Show information
show_info(){
    echo ""
    show_write_log "+-----"
    show_write_log "| SUCESSFUL! Your informations:"
    if [ "${FIRST_OPTION}" == "--account" ]
    then
        show_backup_config
        show_write_log "+-----"
    elif [ "${FIRST_OPTION}" == "--config" ]
    then
        if [ "${SECOND_OPTION}" == "global" ]
        then
            show_global_config
        elif [ "${SECOND_OPTION}" == "show" ]
        then
            EMAIL_USER=`cat ${BUTDR_CONF} | grep "^EMAIL_USER=" | cut -d"=" -f2`
            EMAIL_PASS=`cat ${BUTDR_CONF} | grep "^EMAIL_PASS=" | cut -d"=" -f2`
            EMAIL_TO=`cat ${BUTDR_CONF} | grep "^EMAIL_TO=" | cut -d"=" -f2`
            show_global_config
            show_backup_config
        else
            show_backup_config
        fi
        show_write_log "+-----"
    else
        show_global_config
        show_backup_config
        show_write_log "+-----"
        echo ""
        if [[ "${OS}" == "Ubuntu" ]] || [[ "${OS}" == "Debian" ]]
        then
            echo "IMPORTANT: Please run command to use butgg: source ${HOME}/.profile "
        fi
        echo "If you get trouble when use butgg.bash please report here:"
        echo "https://github.com/mbrother2/backuptogoogle/issues"
    fi
}

# Show help
_help(){
    echo "butdr.bash - Backup to Cloud solution"
    echo ""
    echo "Usage: butdr.bash [option] [command]"
    echo ""
    echo "Options:"
    echo "  --help          show this help message and exit"
    echo "  --setup         setup or reset all scripts & config file"
    echo "  --account       reset account"
    echo "    reset         reset all accounts"
    echo "  --config        config global or backup file"
    echo "    backup-single config backup file for single account"
    echo "    global        config global file"
    echo "    show          show all configs"
    echo "  --update        update butdr.bash & cron_backup.bash to latest version"
    echo "  --uninstall     remove all butdr scripts and ${HOME}.config directory"
}

# Setup or reset all scripts & config file
_setup(){
    rm -rf ${ACCT_DIR} ${BUTDR_CONF}/butgg.conf ${RCLONE_CONF}
    rm -rf ${RCLONE_BIN} ${CRON_BACKUP} ${SETUP_FILE}
    check_log_file
    detect_os
    check_network
    download_file
    download_rclone
    setup_drive
    create_config googledrive
    config_global
    setup_cron
    show_info
}

# Reset account
_account(){
    List_option=(reset)
    check_option list "${SECOND_OPTION}" "${List_option[*]}"
    if [ $? -ne 0 ]
    then
        _help
        exit 1
    fi
    if [ "${FIRST_OPTION}" == "--account" ]
    then
        check_log_file
    fi
    case $1 in
        reset)   account_reset ;;
    esac
    if [ "${FIRST_OPTION}" == "--account" ]
    then
        show_info
    fi
}

# Config global or backup file
_config(){
    List_option=(backup-single global show)
    check_option list "${SECOND_OPTION}" "${List_option[*]}"
    if [ $? -ne 0 ]
    then
        _help
        exit 1
    fi
    if [ "${FIRST_OPTION}" == "--config" ]
    then
        check_log_file
    fi
    case $1 in
        backup-single) config_backup_single ;;
        global)        config_global ;;
        show)          show_info ;;
    esac
    if [[ "${FIRST_OPTION}" == "--config" ]] && [[ "${SECOND_OPTION}" != "show" ]]
    then
        show_info
    fi
}

# Update butdr.bash & cron_backup.bash to latest version
_update(){
    check_log_file
    detect_os
    check_network
    download_file
    show_write_log "`change_color green [INFO]` Update butdr successful"
}

# Remove all butdr scripts and ${HOME}.config directory
_uninstall(){
    check_log_file
    show_write_log "Removing all butdr.bash scripts..."
    rm -f ${RCLONE_BIN} ${CRON_BACKUP} ${SETUP_FILE}
    detect_error "Remove all butdr.bash scripts successful" "[ERROR]" "Can not remove all butdr.bash scripts. Please check permission of these files"
    read -p " Do you want remove ${CONF_DIR} directory?(y/n) " REMOVE_RCLONE_DIR
    if [[ "${REMOVE_RCLONE_DIR}" == "y" ]] || [[ "${REMOVE_RCLONE_DIR}" == "Y" ]]
    then
        rm -rf ${CONF_DIR}
        if [ $? -eq 0 ]
        then
            echo "`date '+[ %d/%m/%Y %H:%M:%S ]' `Remove directory ${CONF_DIR} successful"
        else
            show_write_log "[ERROR] Can not remove directory ${CONF_DIR}. Please check permission of this directory"
        fi
    else
        show_write_log "Skip remove ${CONF_DIR} directory"
    fi
}

# Main functions
if [ -z ${FIRST_OPTION} ]
then
    echo -n "${RED}Missing option${REMOVE}"
    _help
else
    case ${FIRST_OPTION} in
        --help)      _help ;;
        --setup)     _setup ;;
        --account)   _account ${SECOND_OPTION};;
        --config)    _config  ${SECOND_OPTION};;
        --update)    _update ;;
        --uninstall) _uninstall ;;
        *)           echo "No such option ${FIRST_OPTION}"; _help ;;
    esac
fi