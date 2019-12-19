#!/bin/bash

# Setup variables
BIN_DIR="${HOME}/bin"
CONF_DIR="${HOME}/.config"
ACCT_DIR="${CONF_DIR}/accounts"
BUTDR_CONF="${CONF_DIR}/butdr.conf"
BUTDR_DEBUG="${CONF_DIR}/detail.log"
BUTDR_EXCLUDE="${CONF_DIR}/exclude.list"
RCLONE_BIN="${BIN_DIR}/rclone"
DF_BACKUP_DIR="${HOME}/backup"
DF_TAR_BEFORE_UPLOAD="No"
DF_SYNC_FILE="No"
DF_LOG_FILE="${CONF_DIR}/butdr.log"
DF_DAY_REMOVE="7"
DF_DRIVE_FOLDER_ID="None"
DF_EMAIL_USER="None"
DF_EMAIL_PASS="None"
DF_EMAIL_TO="None"
FIRST_OPTION=$1

# Date variables
TODAY=`date +"%d_%m_%Y"`
RANDOM_STRING=`date +%s | sha256sum | base64 | head -c 16`

# Color variables
GREEN='\e[32m'
RED='\e[31m'
YELLOW='\e[33m'
REMOVE='\e[0m'

# Detect error
detect_error(){
    if [ $? -ne 0 ]
    then
        show_write_log "[${CURRENT_ACCOUNT}] `change_color red $3` $4. Exit"
        send_error_email "butdr $3 - [${CURRENT_ACCOUNT}]" "$4"
        exit 1
    else
        show_write_log "[${CURRENT_ACCOUNT}] `change_color green $1` $2"
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

# Show processing and write log
show_write_log(){
    if [ "${FIRST_OPTION}" == "-v" ]
    then
        echo `date "+[ %d/%m/%Y %H:%M:%S ]"` $1
    fi
    echo `date "+[ %d/%m/%Y %H:%M:%S ]"` $1 >> ${LOG_FILE}
}

# Check file type
check_file_type(){
    if [ -d $1 ]
    then
        FILE_TYPE="directory"
    elif [ -f $1 ]
    then
        FILE_TYPE="file"
    else
        show_write_log "`change_color red [CHECK][FAIL]` Can not detect file type for $1. Exit"
        exit 1
    fi
}

# Detect OS
detect_os(){
    show_write_log "Checking OS..."
    if [ -f /etc/os-release ]
    then
        OS=`cat /etc/os-release | grep "^NAME=" | cut -d'"' -f2 | awk '{print $1}'`
        show_write_log "OS supported"
    else
        show_write_log "Sorry! We do not support your OS. Exit"
        exit 1
    fi
}

# Check config
check_config(){
    if [ $2 == LOG_FILE ]
    then
        show_write_log "---"
    fi
    if [ "$4" == "" ]
    then
        VALUE=$3
        if [ -f $1 ]
        then
            sed -i "/^$2=/d" $1
        fi
        echo "$2=$VALUE" >> $1
        show_write_log "`change_color yellow [WARNING]` $2 does not exist. Use default config"
    else
        VALUE=$4
    fi
    VAR=$2
    eval "$VAR"="$VALUE"
    if [ $3 == LOG_FILE ]
    then
        show_write_log "---"
    fi
}

# Get global config
get_config_global(){
    if [ ! -f ${BUTDR_CONF} ]
    then
        check_config ${BUTDR_CONF} LOG_FILE   ${DF_LOG_FILE}
        check_config ${BUTDR_CONF} EMAIL_USER ${DF_EMAIL_USER}
        check_config ${BUTDR_CONF} EMAIL_PASS ${DF_EMAIL_PASS}
        check_config ${BUTDR_CONF} EMAIL_TO   ${DF_EMAIL_TO}
    else
        LOG_FILE=`cat   ${BUTDR_CONF} | grep "^LOG_FILE"   | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config ${BUTDR_CONF} LOG_FILE   ${DF_LOG_FILE}   ${LOG_FILE}
        EMAIL_USER=`cat ${BUTDR_CONF} | grep "^EMAIL_USER" | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config ${BUTDR_CONF} EMAIL_USER ${DF_EMAIL_USER} ${EMAIL_USER}
        EMAIL_PASS=`cat ${BUTDR_CONF} | grep "^EMAIL_PASS" | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config ${BUTDR_CONF} EMAIL_PASS ${DF_EMAIL_PASS} ${EMAIL_PASS}
        EMAIL_TO=`cat   ${BUTDR_CONF} | grep   "^EMAIL_TO" | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config ${BUTDR_CONF} EMAIL_TO   ${DF_EMAIL_TO}   ${EMAIL_TO}
    fi
}

# Get backup config
get_config_backup(){
    if [ ! -f $1 ]
    then
        check_config $1 BACKUP_DIR ${DF_BACKUP_DIR}
        check_config $1 DAY_REMOVE ${DF_DAY_REMOVE}
        check_config $1 DRIVE_FOLDER_ID  ${DF_DRIVE_FOLDER_ID}
        check_config $1 SYNC_FILE  ${DF_SYNC_FILE}
        check_config $1 TAR_BEFORE_UPLOAD ${DF_TAR_BEFORE_UPLOAD}
    else
        BACKUP_DIR=`cat $1 | grep "^BACKUP_DIR" | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config $1 BACKUP_DIR ${DF_BACKUP_DIR} ${BACKUP_DIR}         
        DAY_REMOVE=`cat $1 | grep "^DAY_REMOVE" | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config $1 DAY_REMOVE ${DF_DAY_REMOVE} ${DAY_REMOVE}
        DRIVE_FOLDER_ID=`cat $1 | grep "^DRIVE_FOLDER_ID"  | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config $1 DRIVE_FOLDER_ID ${DF_DRIVE_FOLDER_ID} ${DRIVE_FOLDER_ID}
        SYNC_FILE=`cat $1 | grep "^SYNC_FILE"  | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config $1 SYNC_FILE ${DF_SYNC_FILE} ${SYNC_FILE}
        TAR_BEFORE_UPLOAD=`cat $1 | grep "^TAR_BEFORE_UPLOAD" | cut -d"=" -f2 | sed 's/"//g' | sed "s/'//g"`
        check_config $1 TAR_BEFORE_UPLOAD ${DF_TAR_BEFORE_UPLOAD} ${TAR_BEFORE_UPLOAD}
    fi
}

# Check infomations before upload to Cloud
check_info(){
    if [ ! -d "${BACKUP_DIR}" ]
    then       
        show_write_log "`change_color red [CHECK][FAIL]` Directory ${BACKUP_DIR} does not exist. Exit"
        send_error_email "butdr [CHECK][FAIL]" "Directory ${BACKUP_DIR} does not exist"
        exit 1
    fi
}

# Send error email
send_error_email(){
    if [ "${EMAIL_USER}" == "None" ]
    then
        show_write_log "`change_color yellow [WARNING]` Email not config, do not send error email"
    else
        show_write_log "Sending error email..."
        curl -s --url "smtp://smtp.gmail.com:587" --ssl-reqd --mail-from "${EMAIL_USER}" --mail-rcpt "${EMAIL_TO}" --user "${EMAIL_USER}:${EMAIL_PASS}" -T <(echo -e "From: ${EMAIL_USER}\nTo: ${EMAIL_TO}\nSubject: $1\n\n $2")
        if [ $? -ne 0 ]
        then
            echo "" >> ${BUTDR_DEBUG}
            echo `date "+[ %d/%m/%Y %H:%M:%S ]"` "---" >> ${BUTDR_DEBUG}
            curl -v --url "smtp://smtp.gmail.com:587" --ssl-reqd --mail-from "${EMAIL_USER}" --mail-rcpt "${EMAIL_TO}" --user "${EMAIL_USER}:${EMAIL_PASS}" -T <(echo -e "From: ${EMAIL_USER}\nTo: ${EMAIL_TO}\nSubject: $1\n\n $2") --stderr ${BUTDR_DEBUG}_${TODAY}
            cat ${BUTDR_DEBUG}_${TODAY} >> ${BUTDR_DEBUG}
            rm -f ${BUTDR_DEBUG}_${TODAY}
            show_write_log "`change_color red [EMAIL][FAIL]` Can not send error email. See ${BUTDR_DEBUG} for more detail"            
        else
            show_write_log "Send error email successful"
        fi
    fi
}

# Check Google folder ID
check_drive_id(){
    show_write_log "[${CURRENT_ACCOUNT}] Checking Google folder ID..."
    ${RCLONE_BIN} lsd googledrive: &>/dev/null
    detect_error "[INFO]" "Check Google folder ID successful" "[CHECK][FAIL]" "Can not find Google folder ID"
    CHECK_BACKUP_DIR=`${RCLONE_BIN} lsd googledrive: | awk '{print $5}' | grep -c "${TODAY}"`  
    if [ ${CHECK_BACKUP_DIR} -eq 0 ]
    then
        show_write_log "[${CURRENT_ACCOUNT}] Directory ${TODAY} does not exist. Creating..."
        ${RCLONE_BIN} mkdir googledrive:${TODAY}
        detect_error "[CREATE]" "Created directory ${TODAY} successful" "[CREATE][FAIL]" "Can not create directory ${TODAY}"
    else
        show_write_log "[${CURRENT_ACCOUNT}] Directory ${TODAY} existed. Skipping..."
    fi
}

# Run upload to Cloud
run_upload(){
    if [ "${TAR_BEFORE_UPLOAD}" == "Yes" ]
    then
        show_write_log "[${CURRENT_ACCOUNT}] Compressing backup directory..."
        cd ${BACKUP_DIR}        
        BACKUP_DIR_NAME=`basename ${BACKUP_DIR}`
        tar -zcf ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz *
        detect_error "[COMPRESS]" "Compress ${BACKUP_DIR} successful" "[COMPRESS][FAIL]" "Can not compress ${BACKUP_DIR}"
        show_write_log "[${CURRENT_ACCOUNT}] Uploading ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz to directory ${TODAY}..."
        ${RCLONE_BIN} copy ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz googledrive:${TODAY}
        detect_error "[UPLOAD]" "Uploaded ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz to directory ${TODAY}" "[UPLOAD][FAIL]" "Can not upload to Cloud"
        show_write_log "[${CURRENT_ACCOUNT}] Removing ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz after upload..."
        rm -f ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz
        if [ $? -ne 0 ]
        then
            show_write_log "[${CURRENT_ACCOUNT}] `change_color red [REMOVE][FAIL]` Can not remove ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz. You must delete it manually"
            send_error_email "butdr [REMOVE][FAIL]" "Can not remove ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz. You must delete it manually"  
        else
            show_write_log "[${CURRENT_ACCOUNT}] `change_color green [REMOVE]` Remove ${BACKUP_DIR_NAME}_${RANDOM_STRING}.tar.gz successful"
        fi
    elif [ "${TAR_BEFORE_UPLOAD}" == "No" ]
    then
        BACKUP_DIR=`realpath ${BACKUP_DIR}`
        if [ -f "${ACCT_DIR}/${CURRENT_ACCOUNT}.include" ]
        then
            show_write_log "[${CURRENT_ACCOUNT}] `change_color green [INFO]` File ${CURRENT_ACCOUNT}.include exists, only upload file & directories inside it"
            ${RCLONE_BIN} copy ${BACKUP_DIR} googledrive:${TODAY} --create-empty-src-dirs --include-from ${ACCT_DIR}/googledrive.include
            detect_error "[UPLOAD]" "Finish! All files and directories in ${ACCT_DIR}/${CURRENT_ACCOUNT}.list are uploaded to Cloud" "[UPLOAD][FAIL]" "Can not upload to Cloud"
        else
            show_write_log "[${CURRENT_ACCOUNT}] `change_color green [INFO]` You do not compress directory before upload"
            show_write_log "[${CURRENT_ACCOUNT}] Uploading from ${BACKUP_DIR} to ${TODAY} on Cloud"
            if [ -f "${ACCT_DIR}/${CURRENT_ACCOUNT}.exclude" ]
            then
                ${RCLONE_BIN} copy ${BACKUP_DIR} googledrive:${TODAY} --create-empty-src-dirs --exclude-from ${ACCT_DIR}/googledrive.exclude
            else
                ${RCLONE_BIN} copy ${BACKUP_DIR} googledrive:${TODAY} --create-empty-src-dirs
            fi
            detect_error "[UPLOAD]" "Finish! All files and directories in ${BACKUP_DIR} are uploaded to Cloud" "[UPLOAD][FAIL]" "Can not upload to Cloud"
        fi
    else
        show_write_log "[${CURRENT_ACCOUNT}] `change_color yellow [CHECK][FAIL]` Option TAR_BEFORE_UPLOAD=${TAR_BEFORE_UPLOAD} not support. Only Yes or No. Exit"
        send_error_email "butdr [CHECK][FAIL]" "Option TAR_BEFORE_UPLOAD=${TAR_BEFORE_UPLOAD} not support"
        exit 1
    fi
}

# Remove old directory on Google Drive
remove_old_dir(){
    OLD_BACKUP_DAY=`date +%d_%m_%Y -d "-${DAY_REMOVE} day"`
    CHECK_OLD_BACKUP_DIR=`${RCLONE_BIN} lsd googledrive: | awk '{print $5}' | grep -c "${OLD_BACKUP_DAY}"`  
    if [ ${CHECK_OLD_BACKUP_DIR} -eq 0 ]
    then
        show_write_log "[${CURRENT_ACCOUNT}] Directory ${OLD_BACKUP_DAY} does not exist. Nothing need remove!"
    else
        ${RCLONE_BIN} purge googledrive:${OLD_BACKUP_DAY} --drive-use-trash=false
        detect_error "[REMOVE]" "Removed directory ${OLD_BACKUP_DAY} successful" "[REMOVE][FAIL]" "Directory ${OLD_BACKUP_DAY} exists but can not remove!"
    fi
}

# Sync data from local to Google Drive
run_sync(){
    show_write_log "[${CURRENT_ACCOUNT}] Syncing ${BACKUP_DIR} to Cloud..."
    ${RCLONE_BIN} sync ${BACKUP_DIR} googledrive: --create-empty-src-dirs
    detect_error "[SYNC]" "Finish! All files and directories in ${BACKUP_DIR} are synced to Cloud" "[SYNC][FAIL]" "Can not Sync with Cloud"
}

# Main functions
get_config_global
detect_os
show_write_log "Start upload to Cloud..."
CURRENT_ACCOUNT=`ls -1 ${ACCT_DIR} | grep ".conf$" | head -1 | sed 's/.conf//'`
get_config_backup ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf
check_info
if [ "${SYNC_FILE}" == "No" ]
then
    check_drive_id
    run_upload
    remove_old_dir
elif [ "${SYNC_FILE}" == "Yes" ]
then
    run_sync
else
    show_write_log "`change_color yellow [CHECK][FAIL]` Option SYNC_FILE=${SYNC_FILE} not support. Only Yes or No. Exit"
    send_error_email "butdr [CHECK][FAIL]" "Option SYNC_FILE=${SYNC_FILE} not support"
    exit 1
fi
show_write_log "Finish! All files and directories are uploaded or synced to Cloud"