# butdr
Backup to Cloud solution use [rclone](https://github.com/rclone/rclone)
---

# Plan
- Support Yandex

# What can this script do?
- Download & config rclone with your [Cloud](https://github.com/mbrother2/butdr/blob/master/README.md#cloud-support) credential
- Create cron auto backup
- Exclude/include file/directory when run cron backup
- Sync backup directory from local to Cloud
- Compress backup directory before upload
- Send error email if upload to Cloud fail
- Auto remove old backup on Cloud
- Run upload from your backup directory to Cloud whenever you want
- Detail log

# Structure
```
$HOME (/root or /home/$USER)
   ├── bin
   │    ├── butdr.bash
   │    ├── cron_backup.bash
   │    └── rclone
   │
   └── .config
        ├── accounts
        │   ├── <cloud>.conf
        │   ├── <cloud>.exclude
        │   └── <cloud>.include
        ├── butdr.conf
        ├── butdr.log
        ├── detail.log
        └── rclone
            └── rclone.conf

```

# OS support(x86_64):
- **Linux:** CentOS, Debian, Ubuntu, openSUSE

# Cloud support:
- Google Drive
- Dropbox

# How to use
**On Linux system:**
```
curl -o butdr.bash https://raw.githubusercontent.com/mbrother2/butdr/master/butdr.bash
bash butdr.bash --setup
```

# Wiki
### Common
##### [What is the option SYNC_FILE?](https://github.com/mbrother2/backuptogoogle/wiki/What-is-the-option-SYNC_FILE%3F)

### Google Drive( drive)
##### [Create own Google credential step by step](https://github.com/mbrother2/backuptogoogle/wiki/Create-own-Google-credential-step-by-step)
##### [Get Google folder ID](https://github.com/mbrother2/backuptogoogle/wiki/Get-Google-folder-ID)
##### [Turn on 2 Step Verification & create app's password for Google email](https://github.com/mbrother2/backuptogoogle/wiki/Turn-on-2-Step-Verification-&-create-app's-password-for-Google-email)

### Dropbox( dropbox)
##### [Create own Dropbox credential step by step](https://github.com/mbrother2/butdr/wiki/Create-own-Dropbox-credential-step-by-step)

# Change log
https://github.com/mbrother2/butdr/blob/master/CHANGLOG.md

# Options
Run command `bash butdr.bash --help` to show all options( After install you only need run `butdr.bash --help`
```
butdr@ubuntu1804:~$ butdr.bash --help
butdr.bash - Backup to Cloud solution

Usage: butdr.bash [option] [command]

Options:
  --help          show this help message and exit
  --setup         setup or reset all scripts & config file
  --account       reset account
    reset         reset all accounts
  --config        config global or backup file
    backup-single config backup file for single account
    global        config global file
    show          show all configs
  --update        update butdr.bash & cron_backup.bash to latest version
  --uninstall     remove all butdr scripts and /home/butdr/.config directory
```

###### 1. Setup
`butdr.bash --setup`
Setup or reset all scripts & config file
##### Example
```
butdr@ubuntu1804:~$ bash butdr.bash --setup
[ 19/12/2019 12:03:27 ] ---
[ 19/12/2019 12:03:27 ] Creating necessary directory...
[ 19/12/2019 12:03:27 ] Directory /home/butdr/.config existed. Skip
[ 19/12/2019 12:03:27 ] Check write to /home/butdr/.config successful
[ 19/12/2019 12:03:27 ] Create directory /home/butdr/.config/accounts successful
[ 19/12/2019 12:03:27 ] Check write to /home/butdr/.config/accounts successful
[ 19/12/2019 12:03:27 ] Directory /home/butdr/bin existed. Skip
[ 19/12/2019 12:03:27 ] Check write to /home/butdr/bin successful
[ 19/12/2019 12:03:27 ] Checking OS...
[ 19/12/2019 12:03:27 ] OS supported
[ 19/12/2019 12:03:27 ] Checking necessary package...
[ 19/12/2019 12:03:27 ] Package curl is installed
[ 19/12/2019 12:03:27 ] Package unzip is installed
[ 19/12/2019 12:03:27 ] Cheking network...
[ 19/12/2019 12:03:27 ] Connect Github successful
[ 19/12/2019 12:03:29 ] Connect rclone successful
[ 19/12/2019 12:03:29 ] Downloading script cron_backup from github...
[ 19/12/2019 12:03:29 ] Check md5sum for file cron_backup.bash successful
[ 19/12/2019 12:03:30 ] Downloading script butdr from github...
[ 19/12/2019 12:03:30 ] Check md5sum for file butdr.bash successful
[ 19/12/2019 12:03:30 ] Downloading rclone from homepage...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11.1M  100 11.1M    0     0   888k      0  0:00:12  0:00:12 --:--:-- 1183k
[ 19/12/2019 12:03:43 ] Download rclone successful

Read more: https://github.com/mbrother2/backuptogoogle/wiki/Create-own-Google-credential-step-by-step
 Your Google API client_id: xxxxxx
 Your Google API client_secret: xxxxxx

Read more https://github.com/mbrother2/backuptogoogle/wiki/Get-Google-folder-ID
 Your Google folder ID: 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
2019/12/19 13:35:04 NOTICE: Config file "/home/butdr/.config/rclone/rclone.conf" not found - using defaults
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
Auto confirm is set: answering No, override by setting config parameter config_is_local=true
If your browser doesn't open automatically go to the following link: https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=xxxxxx&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive&state=A6Joak1v_mTJ_Yct8i3diQ
Log in and authorize rclone for access
Enter verification code> 4/xxxxxx
--------------------
[googledrive]
type = drive
root_folder_id = 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
config_is_local = false
scope = drive
client_id = xxxxxx
client_secret = xxxxxx
token = {"access_token":"ya29.Il-xxxxxx","token_type":"Bearer","refresh_token":"1//xxxxxx","expiry":"2019-12-19T14:35:26.759362203+07:00"}
--------------------

 Which directory on your server do you want to upload to account googledrive?(default /home/butdr/backup): 
 How many days do you want to keep backup on Google Drive?(default 7): 

Read more https://github.com/mbrother2/backuptogoogle/wiki/What-is-the-option-SYNC_FILE%3F
 Do you want only sync file(default no)(y/n): 
 Do you want compress directory before upload?(default no)(y/n): 
[ 19/12/2019 13:35:31 ] Setup config file for account googledrive successful
[ 19/12/2019 13:35:31 ] Setting up global config file...

Read more https://github.com/mbrother2/backuptogoogle/wiki/Turn-on-2-Step-Verification-&-create-app's-password-for-Google-email
 Do you want to send email if upload error(default no)(y/n): 
[ 19/12/2019 13:35:31 ] Setup global config file successful

[ 19/12/2019 13:35:31 ] Setting up cron backup...
[ 19/12/2019 13:35:31 ] Cron backup existed. Skip

[ 19/12/2019 13:35:31 ] +-----
[ 19/12/2019 13:35:31 ] | SUCESSFUL! Your informations:
[ 19/12/2019 13:35:31 ] |---
[ 19/12/2019 13:35:31 ] | Your email         : None
[ 19/12/2019 13:35:31 ] | Email password     : None
[ 19/12/2019 13:35:31 ] | Email notify       : None
[ 19/12/2019 13:35:31 ] | Global config file : /home/butdr/.config/butdr.conf
[ 19/12/2019 13:35:32 ] |---
[ 19/12/2019 13:35:32 ] | Account            : googledrive
[ 19/12/2019 13:35:32 ] | Backup dir         : /home/butdr/backup
[ 19/12/2019 13:35:32 ] | Keep backup        : 7 days
[ 19/12/2019 13:35:32 ] | Google folder ID   : 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
[ 19/12/2019 13:35:32 ] | Sync file          : No
[ 19/12/2019 13:35:32 ] | Tar before upload  : No
[ 19/12/2019 13:35:32 ] +-----

IMPORTANT: Please run command to use butgg: source /home/butdr/.profile 
If you get trouble when use butgg.bash please report here:
https://github.com/mbrother2/butdr/issues
```

###### 2. Account
`butdr.bash --account reset`
Reset account
##### Example
```
butdr@ubuntu1804:~$ butdr.bash --account reset
[ 19/12/2019 14:03:58 ] ---
[ 19/12/2019 14:03:58 ] Creating necessary directory...
[ 19/12/2019 14:03:58 ] Directory /home/butdr/.config existed. Skip
[ 19/12/2019 14:03:58 ] Check write to /home/butdr/.config successful
[ 19/12/2019 14:03:58 ] Directory /home/butdr/.config/accounts existed. Skip
[ 19/12/2019 14:03:58 ] Check write to /home/butdr/.config/accounts successful
[ 19/12/2019 14:03:58 ] Directory /home/butdr/bin existed. Skip
[ 19/12/2019 14:03:58 ] Check write to /home/butdr/bin successful
[ 19/12/2019 14:03:58 ] Creating googledrive account...

Read more: https://github.com/mbrother2/backuptogoogle/wiki/Create-own-Google-credential-step-by-step
 Your Google API client_id: xxxxxx
 Your Google API client_secret: xxxxxx

Read more https://github.com/mbrother2/backuptogoogle/wiki/Get-Google-folder-ID
 Your Google folder ID: 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
2019/12/19 14:04:18 NOTICE: Config file "/home/butdr/.config/rclone/rclone.conf" not found - using defaults
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
Auto confirm is set: answering No, override by setting config parameter config_is_local=true
If your browser doesn't open automatically go to the following link: https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=xxxxxx&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive&state=G33rjrgGHNXRKPs59H5JOQ
Log in and authorize rclone for access
Enter verification code> 4/xxxxxx
--------------------
[googledrive]
type = drive
config_is_local = false
scope = drive
client_id = xxxxxx
client_secret = xxxxxx
root_folder_id = 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
token = {"access_token":"ya29.Il-xxxxxx","token_type":"Bearer","refresh_token":"1//xxxxxx","expiry":"2019-12-19T15:04:43.403854207+07:00"}
--------------------

[ 19/12/2019 14:04:43 ] +-----
[ 19/12/2019 14:04:43 ] | SUCESSFUL! Your informations:
[ 19/12/2019 14:04:43 ] |---
[ 19/12/2019 14:04:43 ] | Account            : googledrive
[ 19/12/2019 14:04:43 ] | Backup dir         : /home/butdr/backup
[ 19/12/2019 14:04:43 ] | Keep backup        : 7 days
[ 19/12/2019 14:04:43 ] | Google folder ID   : 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
[ 19/12/2019 14:04:43 ] | Sync file          : No
[ 19/12/2019 14:04:43 ] | Tar before upload  : No
[ 19/12/2019 14:04:43 ] +-----
```

###### 3. Config
`butdr.bash --config backup-single`
Config backup file for single account
##### Example
```
butdr@ubuntu1804:~$ butdr.bash --config backup-single
[ 19/12/2019 14:08:41 ] ---
[ 19/12/2019 14:08:41 ] Creating necessary directory...
[ 19/12/2019 14:08:41 ] Directory /home/butdr/.config existed. Skip
[ 19/12/2019 14:08:41 ] Check write to /home/butdr/.config successful
[ 19/12/2019 14:08:41 ] Directory /home/butdr/.config/accounts existed. Skip
[ 19/12/2019 14:08:41 ] Check write to /home/butdr/.config/accounts successful
[ 19/12/2019 14:08:41 ] Directory /home/butdr/bin existed. Skip
[ 19/12/2019 14:08:42 ] Check write to /home/butdr/bin successful

[ 19/12/2019 14:08:42 ] Setting up backup config file...

 Which directory on your server do you want to upload to account googledrive?(default /home/butdr/backup): /home/butdr/backup2
 How many days do you want to keep backup on Google Drive?(default 7): 30

Read more https://github.com/mbrother2/backuptogoogle/wiki/What-is-the-option-SYNC_FILE%3F
 Do you want only sync file(default no)(y/n): y

Read more https://github.com/mbrother2/backuptogoogle/wiki/Get-Google-folder-ID
Because you choose sync file method, so you must enter exactly Google folder ID here!
 Your Google folder ID(default None): 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
[ 19/12/2019 14:09:03 ] [WARNING] Directory /home/butdr/backup2 does not exist! Ensure you will be create it after.
[ 19/12/2019 14:09:06 ] Setup config file for account googledrive successful

[ 19/12/2019 14:09:06 ] +-----
[ 19/12/2019 14:09:06 ] | SUCESSFUL! Your informations:
[ 19/12/2019 14:09:06 ] |---
[ 19/12/2019 14:09:06 ] | Account            : googledrive
[ 19/12/2019 14:09:06 ] | Backup dir         : /home/butdr/backup2
[ 19/12/2019 14:09:06 ] | Keep backup        : 30 days
[ 19/12/2019 14:09:06 ] | Google folder ID   : 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
[ 19/12/2019 14:09:06 ] | Sync file          : Yes
[ 19/12/2019 14:09:06 ] | Tar before upload  : No
[ 19/12/2019 14:09:06 ] +-----
```
`butdr.bash --config global`
Config global file
##### Example
```
butdr@ubuntu1804:~$ butdr.bash --config global
[ 19/12/2019 14:10:48 ] ---
[ 19/12/2019 14:10:48 ] Creating necessary directory...
[ 19/12/2019 14:10:48 ] Directory /home/butdr/.config existed. Skip
[ 19/12/2019 14:10:49 ] Check write to /home/butdr/.config successful
[ 19/12/2019 14:10:49 ] Directory /home/butdr/.config/accounts existed. Skip
[ 19/12/2019 14:10:49 ] Check write to /home/butdr/.config/accounts successful
[ 19/12/2019 14:10:49 ] Directory /home/butdr/bin existed. Skip
[ 19/12/2019 14:10:49 ] Check write to /home/butdr/bin successful
[ 19/12/2019 14:10:49 ] Setting up global config file...

Read more https://github.com/mbrother2/backuptogoogle/wiki/Turn-on-2-Step-Verification-&-create-app's-password-for-Google-email
 Do you want to send email if upload error(default no)(y/n): y
 Your Google email user name: backupxxxxxx@gmail.com
 Your Google email password: xxxxxx
 Which email will be receive notify?: backupxxxxxx@gmail.com
[ 19/12/2019 14:11:11 ] Setup global config file successful

[ 19/12/2019 14:11:11 ] +-----
[ 19/12/2019 14:11:11 ] | SUCESSFUL! Your informations:
[ 19/12/2019 14:11:11 ] |---
[ 19/12/2019 14:11:11 ] | Your email         : backupxxxxxx@gmail.com
[ 19/12/2019 14:11:11 ] | Email password     : xxxxxx
[ 19/12/2019 14:11:11 ] | Email notify       : backupxxxxxx@gmail.com
[ 19/12/2019 14:11:11 ] | Global config file : /home/butdr/.config/butdr.conf
[ 19/12/2019 14:11:11 ] +-----
```
`butdr.bash --config show`
Show all configs
##### Example
```
butdr@ubuntu1804:~$ butdr.bash --config show
[ 19/12/2019 14:12:20 ] ---
[ 19/12/2019 14:12:20 ] Creating necessary directory...
[ 19/12/2019 14:12:20 ] Directory /home/butdr/.config existed. Skip
[ 19/12/2019 14:12:20 ] Check write to /home/butdr/.config successful
[ 19/12/2019 14:12:20 ] Directory /home/butdr/.config/accounts existed. Skip
[ 19/12/2019 14:12:20 ] Check write to /home/butdr/.config/accounts successful
[ 19/12/2019 14:12:20 ] Directory /home/butdr/bin existed. Skip
[ 19/12/2019 14:12:20 ] Check write to /home/butdr/bin successful

[ 19/12/2019 14:12:20 ] +-----
[ 19/12/2019 14:12:20 ] | SUCESSFUL! Your informations:
[ 19/12/2019 14:12:20 ] |---
[ 19/12/2019 14:12:20 ] | Your email         : backupxxxxxx@gmail.com
[ 19/12/2019 14:12:20 ] | Email password     : xxxxxx
[ 19/12/2019 14:12:20 ] | Email notify       : backupxxxxxx@gmail.com
[ 19/12/2019 14:12:20 ] | Global config file : /home/butdr/.config/butdr.conf
[ 19/12/2019 14:12:20 ] |---
[ 19/12/2019 14:12:20 ] | Account            : googledrive
[ 19/12/2019 14:12:20 ] | Backup dir         : /home/butdr/backup2
[ 19/12/2019 14:12:20 ] | Keep backup        : 30 days
[ 19/12/2019 14:12:20 ] | Google folder ID   : 1TQwTpELBtA5SaIi8mIVzVJdcdv_GNzM3
[ 19/12/2019 14:12:20 ] | Sync file          : Yes
[ 19/12/2019 14:12:20 ] | Tar before upload  : No
[ 19/12/2019 14:12:20 ] +-----
```

###### 4. Update
`butdr.bash --update`
Update butdr.bash & cron_backup.bash to latest version
##### Example
```
butdr@ubuntu1804:~$ butdr.bash --update
[ 19/12/2019 14:12:52 ] ---
[ 19/12/2019 14:12:52 ] Creating necessary directory...
[ 19/12/2019 14:12:52 ] Directory /home/butdr/.config existed. Skip
[ 19/12/2019 14:12:52 ] Check write to /home/butdr/.config successful
[ 19/12/2019 14:12:52 ] Directory /home/butdr/.config/accounts existed. Skip
[ 19/12/2019 14:12:52 ] Check write to /home/butdr/.config/accounts successful
[ 19/12/2019 14:12:52 ] Directory /home/butdr/bin existed. Skip
[ 19/12/2019 14:12:52 ] Check write to /home/butdr/bin successful
[ 19/12/2019 14:12:52 ] Checking OS...
[ 19/12/2019 14:12:52 ] OS supported
[ 19/12/2019 14:12:52 ] Checking necessary package...
[ 19/12/2019 14:12:52 ] Package curl is installed
[ 19/12/2019 14:12:52 ] Package unzip is installed
[ 19/12/2019 14:12:52 ] Cheking network...
[ 19/12/2019 14:12:52 ] Connect Github successful
[ 19/12/2019 14:12:52 ] Downloading script cron_backup from github...
[ 19/12/2019 14:12:53 ] Check md5sum for file cron_backup.bash successful
[ 19/12/2019 14:12:53 ] Downloading script butdr from github...
[ 19/12/2019 14:12:54 ] Check md5sum for file butdr.bash successful
[ 19/12/2019 14:12:54 ] [INFO] Update butdr successful
```

###### 5. Uninstall
`butdr.bash --uninstall`
Remove all butdr scripts and /home/butdr.config directory
##### Example
```
butdr@ubuntu1804:~$ butdr.bash --uninstall
[ 19/12/2019 14:16:17 ] ---
[ 19/12/2019 14:16:17 ] Creating necessary directory...
[ 19/12/2019 14:16:17 ] Directory /home/butdr/.config existed. Skip
[ 19/12/2019 14:16:17 ] Check write to /home/butdr/.config successful
[ 19/12/2019 14:16:17 ] Directory /home/butdr/.config/accounts existed. Skip
[ 19/12/2019 14:16:17 ] Check write to /home/butdr/.config/accounts successful
[ 19/12/2019 14:16:17 ] Directory /home/butdr/bin existed. Skip
[ 19/12/2019 14:16:17 ] Check write to /home/butdr/bin successful
[ 19/12/2019 14:16:17 ] Removing all butdr.bash scripts...
[ 19/12/2019 14:16:17 ] Remove all butdr.bash scripts successful
 Do you want remove /home/butdr/.config directory?(y/n) y
[ 19/12/2019 14:16:22 ]Remove directory /home/butdr/.config successful
```

###### 6. Run cron_backup.bash
`cron_backup.bash`
Run upload to Google Drive immediately without show log

`cron_backup.bash -v`
Run upload to Google Drive immediately with show log detail
##### Example
Backup to cloud normaly
```
butdr@ubuntu1804:~$ cron_backup.bash -v
[ 19/12/2019 14:15:52 ] ---
[ 19/12/2019 14:15:52 ] Checking OS...
[ 19/12/2019 14:15:52 ] OS supported
[ 19/12/2019 14:15:52 ] Start upload to Cloud...
[ 19/12/2019 14:15:52 ] [googledrive] Checking Google folder ID...
[ 19/12/2019 14:15:53 ] [googledrive] [INFO] Check Google folder ID successful
[ 19/12/2019 14:15:53 ] [googledrive] Directory 19_12_2019 existed. Skipping...
[ 19/12/2019 14:15:53 ] [googledrive] [INFO] You do not compress directory before upload
[ 19/12/2019 14:15:53 ] [googledrive] Uploading from /home/butdr/backup2 to 19_12_2019 on Cloud
[ 19/12/2019 14:16:07 ] [googledrive] [UPLOAD] Finish! All files and directories in /home/butdr/backup2 are uploaded to Cloud
[ 19/12/2019 14:16:10 ] [googledrive] Directory 19_11_2019 does not exist. Nothing need remove!
[ 19/12/2019 14:16:10 ] Finish! All files and directories are uploaded or synced to Cloud
```

Backup to cloud with SYNC_FILE=yes
```
butdr@ubuntu1804:~$ cron_backup.bash -v
[ 19/12/2019 14:14:08 ] ---
[ 19/12/2019 14:14:08 ] Checking OS...
[ 19/12/2019 14:14:08 ] OS supported
[ 19/12/2019 14:14:08 ] Start upload to Cloud...
[ 19/12/2019 14:14:08 ] [googledrive] Syncing /home/butdr/backup2 to Cloud...
[ 19/12/2019 14:14:44 ] [googledrive] [SYNC] Finish! All files and directories in /home/butdr/backup2 are synced to Cloud
[ 19/12/2019 14:14:44 ] Finish! All files and directories are uploaded or synced to Cloud
```

Backup to cloud with TAR_BEFORE_UPLOAD=Yes
```
butdr@ubuntu1804:~$ cron_backup.bash -v
[ 19/12/2019 14:15:18 ] ---
[ 19/12/2019 14:15:18 ] Checking OS...
[ 19/12/2019 14:15:18 ] OS supported
[ 19/12/2019 14:15:18 ] Start upload to Cloud...
[ 19/12/2019 14:15:18 ] [googledrive] Checking Google folder ID...
[ 19/12/2019 14:15:19 ] [googledrive] [INFO] Check Google folder ID successful
[ 19/12/2019 14:15:20 ] [googledrive] Directory 19_12_2019 does not exist. Creating...
[ 19/12/2019 14:15:25 ] [googledrive] [CREATE] Created directory 19_12_2019 successful
[ 19/12/2019 14:15:25 ] [googledrive] Compressing backup directory...
[ 19/12/2019 14:15:25 ] [googledrive] [COMPRESS] Compress /home/butdr/backup2 successful
[ 19/12/2019 14:15:25 ] [googledrive] Uploading backup2_NjkxNTQ4NTJlMDcw.tar.gz to directory 19_12_2019...
[ 19/12/2019 14:15:28 ] [googledrive] [UPLOAD] Uploaded backup2_NjkxNTQ4NTJlMDcw.tar.gz to directory 19_12_2019
[ 19/12/2019 14:15:28 ] [googledrive] Removing backup2_NjkxNTQ4NTJlMDcw.tar.gz after upload...
[ 19/12/2019 14:15:28 ] [googledrive] [REMOVE] Remove backup2_NjkxNTQ4NTJlMDcw.tar.gz successful
[ 19/12/2019 14:15:29 ] [googledrive] Directory 19_11_2019 does not exist. Nothing need remove!
[ 19/12/2019 14:15:29 ] Finish! All files and directories are uploaded or synced to Cloud
```
