#!/bin/bash

# Setup variables
GITHUB_LINK="https://raw.githubusercontent.com/mbrother2/butdr/master"
BUTDR_WIKI="https://github.com/mbrother2/butdr/wiki"
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
DF_FOLDER_NAME="None"
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
        if [ -z "$3" ]
        then
            echo "Please choose from 1 to $2"
            return 1
        else
            TRAP=`echo $2 | tr -d "[:digit:]"`
            if [ -z "${TRAP}" ]
            then
                if [[ $2 -lt 1 ]] || [[ $2 -gt $3 ]]
                then
                    echo "Please choose from 1 to $3"
                    return 1
                else
                    return 0
                fi
            else
                echo "Please choose from 1 to $3"
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
    create_dir .config/rclone
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
            if [ "$1" == ".config/rclone" ]
            then
                show_write_log "---"
                show_write_log "Creating necessary directory..."
            fi
            show_write_log "Create directory ${HOME}/$1 successful"
        fi
    else
        if [ "$1" == ".config/rclone" ]
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

# Choose Cloud
choose_cloud(){
    echo ""
    echo "Which cloud you will use?"
    echo "1. Google Drive (drive)"
    echo "2. Dropbox (dropbox)"
    echo "3. Yandex (yandex)"
    echo "4. One Drive (onedrive)"
    echo "5. Backblaze (b2)"
    read -p " Your choice: " CHOOSE_CLOUD
    check_option number "${CHOOSE_CLOUD}" 5
    while [ $? -ne 0 ]
    do
        read -p " Your choice: " CHOOSE_CLOUD
        check_option number "${CHOOSE_CLOUD}" 5
    done
    case ${CHOOSE_CLOUD} in
        1) CLOUD_TYPE="drive";    setup_drive ;;
        2) CLOUD_TYPE="dropbox";  setup_dropbox ;;
        3) CLOUD_TYPE="yandex";   setup_yandex ;;
        4) CLOUD_TYPE="onedrive"; setup_onedrive ;;
        5) CLOUD_TYPE="b2";       setup_backblaze ;;
    esac
}

# Setup Google drive account
setup_drive(){
    show_write_log "Creating Google drive account..."
    echo ""
    echo "Read more: ${BUTDR_WIKI}/Create-own-Google-credential-step-by-step"
    read -p " Your Google API client_id: " DRIVE_CLIENT_ID
    read -p " Your Google API client_secret: " DRIVE_CLIENT_SECRET
    echo ""
    echo "Read more ${BUTDR_WIKI}/Get-Google-folder-ID"
    read -p " Your Google folder ID: " DRIVE_FOLDER_ID
    rm -f ${RCLONE_CONF}
    if [[ -z ${DRIVE_CLIENT_ID} ]] || [[ -z ${DRIVE_CLIENT_SECRET} ]]
    then
        show_write_log "`change_color yellow [WARNING]` You're using rclone Google credential, it may be low performance"
        if [ -z ${DRIVE_FOLDER_ID} ]
        then
            ${RCLONE_BIN} config create drive drive config_is_local false scope drive
        else
            ${RCLONE_BIN} config create drive drive config_is_local false scope drive root_folder_id ${DRIVE_FOLDER_ID}
        fi
    else
        if [ -z ${DRIVE_FOLDER_ID} ]
        then
            ${RCLONE_BIN} config create drive drive config_is_local false scope drive client_id ${DRIVE_CLIENT_ID} client_secret ${DRIVE_CLIENT_SECRET}
        else
            ${RCLONE_BIN} config create drive drive config_is_local false scope drive client_id ${DRIVE_CLIENT_ID} client_secret ${DRIVE_CLIENT_SECRET} root_folder_id ${DRIVE_FOLDER_ID}
        fi
    fi
    show_write_log "Checking connect to Google Drive..."
    ${RCLONE_BIN} about drive:
    detect_error "Connect Google Drive successful" "[CONNECT][FAIL]" "Can not connect Google Drive with your credential, please check again"
    write_config "${ACCT_DIR}/drive.conf" DRIVE_FOLDER_ID "${DF_DRIVE_FOLDER_ID}" "${DRIVE_FOLDER_ID}"
    write_config "${ACCT_DIR}/drive.conf" CLOUD_TYPE "${CLOUD_TYPE}"
    write_config ${BUTDR_CONF} CLOUD_TYPE "${CLOUD_TYPE}"
}

# Setup Dropbox account
setup_dropbox(){
    show_write_log "Creating Dropbox account..."
    echo ""
    echo "Read more: ${BUTDR_WIKI}/Create-own-Dropbox-credential-step-by-step"
    read -p " Your Dropbox App key: " DROPBOX_APP_KEY
    read -p " Your Dropbox App secret: " DROPBOX_APP_SECRET
    read -p " Your Dropbox access token: " DROPBOX_ACCESS_TOKEN
    if [[ -z ${DROPBOX_APP_KEY} ]] || [[ -z ${DROPBOX_APP_SECRET} ]] || [[ -z ${DROPBOX_ACCESS_TOKEN} ]]
    then
        show_write_log "`change_color red [FAIL]` butdr only support rclone with your own Dropbox credential. Exit"
        exit 1
    fi
    read -p " Your Dropbox folder name: " DROPBOX_FOLDER_NAME
    rm -f ${RCLONE_CONF}
    cat >> "${RCLONE_CONF}" <<EOF
[dropbox]
type = dropbox
app_key = ${DROPBOX_APP_KEY}
app_secret = ${DROPBOX_APP_SECRET}
token = ${DROPBOX_ACCESS_TOKEN}
EOF
    show_write_log "Checking connect to Dropbox..."
    ${RCLONE_BIN} about dropbox:
    detect_error "Connect Dropbox successful" "[CONNECT][FAIL]" "Can not connect Dropbox with your credential, please check again"
    write_config "${ACCT_DIR}/dropbox.conf" CLOUD_TYPE "${CLOUD_TYPE}"
    write_config "${ACCT_DIR}/dropbox.conf" FOLDER_NAME "${DF_FOLDER_NAME}" "${DROPBOX_FOLDER_NAME}"
    write_config ${BUTDR_CONF} CLOUD_TYPE "${CLOUD_TYPE}"
}

# Setup Yandex account
setup_yandex(){
    show_write_log "Creating Yandex account..."
    echo ""
    echo "Read more: ${BUTDR_WIKI}/Create-own-Yandex-credential-step-by-step"
    read -p " Your Yandex ID: " YANDEX_ID
    read -p " Your Yandex Password: " YANDEX_PASSWORD
    if [[ -z ${YANDEX_ID} ]] || [[ -z ${YANDEX_PASSWORD} ]]
    then
        show_write_log "`change_color red [FAIL]` butdr only support rclone with your own Yandex credential. Exit"
        exit 1
    fi
    read -p " Your Yandex folder name: " YANDEX_FOLDER_NAME
    echo ""
    echo "Authentication needed"
    echo "Go to the following url in your browser:"
    echo "https://oauth.yandex.com/authorize?response_type=code&client_id=${YANDEX_ID}"
    echo ""
    read -p " Enter verification code: " YANDEX_VERIFY_CODE
    YANDEX_TOKEN=`curl -s -X POST https://oauth.yandex.com/token -F grant_type=authorization_code -F code=${YANDEX_VERIFY_CODE} -F client_id=${YANDEX_ID} -F client_secret=${YANDEX_PASSWORD} | sed "s/ //g"`
    rm -f ${RCLONE_CONF}
    cat >> "${RCLONE_CONF}" <<EOF
[yandex]
type = yandex
client_id = ${YANDEX_ID}
client_secret = ${YANDEX_PASSWORD}
token = ${YANDEX_TOKEN}
EOF
    show_write_log "Checking connect to Yandex..."
    ${RCLONE_BIN} about yandex:
    detect_error "Connect Yandex successful" "[CONNECT][FAIL]" "Can not connect Yandex with your credential, please check again"
    write_config "${ACCT_DIR}/yandex.conf" CLOUD_TYPE "${CLOUD_TYPE}"
    write_config "${ACCT_DIR}/yandex.conf" FOLDER_NAME "${DF_FOLDER_NAME}" "${YANDEX_FOLDER_NAME}"
    write_config ${BUTDR_CONF} CLOUD_TYPE "${CLOUD_TYPE}"
}

# Setup One Drive account
setup_onedrive(){
    show_write_log "Creating One Drive account..."
    echo ""
    echo "Read more: ${BUTDR_WIKI}/Create-own-One-Drive-credential-step-by-step"
    read -p " Your One Drive client ID: " ONEDRIVE_CLIENT_ID
    read -p " Your One Drive client secret: " ONEDRIVE_CLIENT_SECRET
    if [[ -z ${ONEDRIVE_CLIENT_ID} ]] || [[ -z ${ONEDRIVE_CLIENT_SECRET} ]]
    then
        show_write_log "`change_color red [FAIL]` butdr only support rclone with your own One Drive credential. Exit"
        exit 1
    fi
    read -p " Your One Drive folder name: " ONEDRIVE_FOLDER_NAME
    echo ""
    echo "Authentication needed"
    echo "Go to the following url in your browser:"
    echo "https://login.live.com/oauth20_authorize.srf?client_id=${ONEDRIVE_CLIENT_ID}&scope=Files.Read+Files.ReadWrite+Files.Read.All+Files.ReadWrite.All+offline_access&response_type=code&redirect_uri=https%3A%2F%2Flogin.microsoftonline.com%2Fcommon%2Foauth2%2Fnativeclient"
    echo ""
    read -p " Enter verification code: " ONEDRIVE_VERIFY_CODE
    ONEDRIVE_TOKEN=`curl -s -X POST "https://login.live.com/oauth20_token.srf" --data-urlencode "redirect_uri=https://login.microsoftonline.com/common/oauth2/nativeclient" --data-urlencode "client_id=${ONEDRIVE_CLIENT_ID}" --data-urlencode "client_secret=${ONEDRIVE_CLIENT_SECRET}" --data-urlencode "code=${ONEDRIVE_VERIFY_CODE}" --data-urlencode "grant_type=authorization_code"`
    ONEDRIVE_REAL_TOKEN=`echo "${ONEDRIVE_TOKEN}" | sed 's/,/\n/g' | grep '"access_token":' | cut -d'"' -f4`
    ONEDRIVE_DRIVE_ID=`curl -s "https://graph.microsoft.com/v1.0/me/drive" --header "Authorization: Bearer ${ONEDRIVE_REAL_TOKEN}" | sed 's/,/\n/g' | grep '"id":' | head -1 | cut -d'"' -f4`
    ONEDRIVE_DRIVE_TYPE=`curl -s "https://graph.microsoft.com/v1.0/me/drive" --header "Authorization: Bearer ${ONEDRIVE_REAL_TOKEN}" | sed 's/,/\n/g' | grep '"driveType":' | head -1 | cut -d'"' -f4`
    rm -f ${RCLONE_CONF}
    cat >> "${RCLONE_CONF}" <<EOF
[onedrive]
type = onedrive
drive_type = ${ONEDRIVE_DRIVE_TYPE}
drive_id = ${ONEDRIVE_DRIVE_ID}
client_id = ${ONEDRIVE_CLIENT_ID}
client_secret = ${ONEDRIVE_CLIENT_SECRET}
token = ${ONEDRIVE_TOKEN}
EOF
    show_write_log "Checking connect to One Drive..."
    ${RCLONE_BIN} about onedrive:
    detect_error "Connect One Drive successful" "[CONNECT][FAIL]" "Can not connect One Drive with your credential, please check again"
    write_config "${ACCT_DIR}/onedrive.conf" CLOUD_TYPE "${CLOUD_TYPE}"
    write_config "${ACCT_DIR}/onedrive.conf" FOLDER_NAME "${DF_FOLDER_NAME}" "${ONEDRIVE_FOLDER_NAME}"
    write_config ${BUTDR_CONF} CLOUD_TYPE "${CLOUD_TYPE}"
}

# Setup Backblaze account
setup_backblaze(){
    show_write_log "Creating Backblaze account..."
    echo ""
    echo "Read more: ${BUTDR_WIKI}/Create-own-Backblaze-credential-step-by-step"
    read -p " Your Backblaze key ID: " BACKBLAZE_KEY_ID
    read -p " Your Backblaze application key: " BACKBLAZE_APPLICATION_KEY
    if [[ -z ${BACKBLAZE_KEY_ID} ]] || [[ -z ${BACKBLAZE_APPLICATION_KEY} ]]
    then
        show_write_log "`change_color red [FAIL]` butdr only support rclone with your own Backblaze credential. Exit"
        exit 1
    fi
    echo ""
    echo "`change_color red [IMPORTANT]` Backblaze limits 100 buckets, so you should create new bucket for backup!"
    echo "Read more: ${BUTDR_WIKI}/Backblaze-Create-new-bucket"
    read -p " Your Backblaze bucket name: " BACKBLAZE_BUCKET_NAME
    rclone config create b2 b2 account ${BACKBLAZE_KEY_ID} key ${BACKBLAZE_APPLICATION_KEY} hard_delete true
    rm -f ${RCLONE_CONF}
    cat >> "${RCLONE_CONF}" <<EOF
[b2]
type = b2
account = ${BACKBLAZE_KEY_ID}
key = ${BACKBLAZE_APPLICATION_KEY}
hard_delete = false
EOF
    show_write_log "Checking connect to Backblaze..."
    ${RCLONE_BIN} lsd b2: | head -1
    detect_error "Connect Backblaze successful" "[CONNECT][FAIL]" "Can not connect Backblaze with your credential, please check again"
    write_config "${ACCT_DIR}/b2.conf" CLOUD_TYPE "${CLOUD_TYPE}"
    write_config "${ACCT_DIR}/b2.conf" FOLDER_NAME "${DF_FOLDER_NAME}" "${BACKBLAZE_BUCKET_NAME}"
    write_config ${BUTDR_CONF} CLOUD_TYPE "${CLOUD_TYPE}"
}

# Create config for Cloud account
create_config(){
    read -p " Which directory on your server do you want to upload to account ${CLOUD_TYPE}?(default ${DF_BACKUP_DIR}): " BACKUP_DIR
    read -p " How many days do you want to keep backup on Cloud?(default ${DF_DAY_REMOVE}): " DAY_REMOVE
    echo ""
    echo "Read more https://github.com/mbrother2/backuptogoogle/wiki/What-is-the-option-SYNC_FILE%3F"
    read -p " Do you want only sync file(default no)(y/n): " SYNC_FILE
    if [ "${CLOUD_TYPE}" == "drive" ]
    then
        DRIVE_FOLDER_ID=`cat ${ACCT_DIR}/${CLOUD_TYPE}.conf | grep "^DRIVE_FOLDER_ID=" | cut -d"=" -f2`
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
    write_config "${ACCT_DIR}/${CLOUD_TYPE}.conf" BACKUP_DIR        "${DF_BACKUP_DIR}"        "${BACKUP_DIR}"
    write_config "${ACCT_DIR}/${CLOUD_TYPE}.conf" DAY_REMOVE        "${DF_DAY_REMOVE}"        "${DAY_REMOVE}"
    write_config "${ACCT_DIR}/${CLOUD_TYPE}.conf" SYNC_FILE         "${DF_SYNC_FILE}"         "${SYNC_FILE}"
    write_config "${ACCT_DIR}/${CLOUD_TYPE}.conf" TAR_BEFORE_UPLOAD "${DF_TAR_BEFORE_UPLOAD}" "${TAR_BEFORE_UPLOAD}"
    if [ "${CLOUD_TYPE}" == "drive" ]
    then
        write_config "${ACCT_DIR}/${CLOUD_TYPE}.conf" DRIVE_FOLDER_ID   "${DF_DRIVE_FOLDER_ID}"   "${DRIVE_FOLDER_ID}"
    fi
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
        show_write_log "Setup config file for account ${CLOUD_TYPE} successful"
    fi
    if [ "${CLOUD_TYPE}" == "drive" ]
    then
        DRIVE_FOLDER_ID=`cat ${ACCT_DIR}/${CLOUD_TYPE}.conf | grep "^DRIVE_FOLDER_ID=" | cut -d"=" -f2`
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
                sed -i "/^\[drive\]$/a root_folder_id = ${DRIVE_FOLDER_ID}" ${RCLONE_CONF}
            else
                sed -i "s/^root_folder_id = .*/root_folder_id = ${DRIVE_FOLDER_ID}/" ${RCLONE_CONF}
            fi
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
    CLOUD_TYPE=`cat ${BUTDR_CONF} | grep "^CLOUD_TYPE=" | cut -d"=" -f2`
    if [ ! -z "${CLOUD_TYPE}" ]
    then
        echo ""
        echo "Current account: ${CLOUD_TYPE}"
        echo "---"
    fi
    choose_cloud
    create_config
}

# Config backup file for single account
config_backup_single(){
    CLOUD_TYPE=`cat ${BUTDR_CONF} | grep "^CLOUD_TYPE=" | cut -d"=" -f2`
    echo ""
    echo "Current account: ${CLOUD_TYPE}"
    echo "---"
    echo ""
    show_write_log "Setting up backup config file..."
    create_config
}

# Show global config
show_global_config(){
    CLOUD_TYPE=`cat ${BUTDR_CONF} | grep "^CLOUD_TYPE=" | cut -d"=" -f2`
    show_write_log "|---"
    show_write_log "| Account type       : ${CLOUD_TYPE}"
    show_write_log "| Your email         : ${EMAIL_USER}"
    show_write_log "| Email password     : ${EMAIL_PASS}"
    show_write_log "| Email notify       : ${EMAIL_TO}"
    show_write_log "| Global config file : ${BUTDR_CONF}"
}

# Show backup config
show_backup_config(){
    CLOUD_TYPE=`cat ${BUTDR_CONF} | grep "^CLOUD_TYPE=" | cut -d"=" -f2`
    CURRENT_ACCOUNT=${CLOUD_TYPE}
    BACKUP_DIR=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^BACKUP_DIR=" | cut -d"=" -f2`
    DAY_REMOVE=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^DAY_REMOVE=" | cut -d"=" -f2`
    BACKUP_DIR=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^BACKUP_DIR=" | cut -d"=" -f2`
    if [ "${CLOUD_TYPE}" == "drive" ]
    then
        DRIVE_FOLDER_ID=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^DRIVE_FOLDER_ID=" | cut -d"=" -f2`
    else
        CLOUD_FOLDER_NAME=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^FOLDER_NAME=" | cut -d"=" -f2`
    fi
    SYNC_FILE=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^SYNC_FILE="  | cut -d"=" -f2`
    TAR_BEFORE_UPLOAD=`cat ${ACCT_DIR}/${CURRENT_ACCOUNT}.conf | grep "^TAR_BEFORE_UPLOAD=" | cut -d"=" -f2`
    show_write_log "|---"
    show_write_log "| Account            : ${CURRENT_ACCOUNT}"
    show_write_log "| Backup dir         : ${BACKUP_DIR}"
    show_write_log "| Keep backup        : ${DAY_REMOVE} days"
    if [ "${CLOUD_TYPE}" == "drive" ]
    then
        show_write_log "| Google folder ID   : ${DRIVE_FOLDER_ID}"
    else
        show_write_log "| Cloud folder name  : ${CLOUD_FOLDER_NAME}"
    fi
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
            echo "IMPORTANT: Please run command to use butdr: source ${HOME}/.profile "
        fi
        echo "If you get trouble when use butgg.bash please report here:"
        echo "https://github.com/mbrother2/butdr/issues"
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
    choose_cloud
    create_config
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
