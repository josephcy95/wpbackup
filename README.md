# wpbackup

Simple shell script to backup WordPress sites installed by WordOps with Rclone. By default WordOps puts `wp-config.php` in each site's root folder; if this is not the case, remove the relevant lines that check for its existence.

## Requirements (For rclone version)
* **WP-CLI:** The WordPress command-line interface. Ensure it's installed and accessible within your system's PATH.
* **Rclone:** A versatile tool for syncing files with cloud storage providers. Install Rclone and set up your desired remote backup location.
* **Storj Access Grant (Strongly Recommended):**  Use Storj Access Grants for authentication instead of API keys or S3 credentials.

## Rclone Setup

1. **Install Rclone:** Follow the instructions for your operating system on the Rclone website: [https://rclone.org/downloads/](https://rclone.org/downloads/)
2. **Configure Remote Location:** Use the `rclone config` command to set up the remote where you want to store your backups. When using Storj, ensure you create an Access Grant.

## Logrotate Setup

1. **Install logrotate (if not already installed):**
   *  Ubuntu/Debian: `sudo apt install logrotate`
   *  CentOS/Red Hat/Fedora: `sudo yum install logrotate`

2. **Create a logrotate Configuration File:**
   Create a file at `/etc/logrotate.d/wpbackuplog` with the following contents:
   ```
   /var/log/wpbackup.log {
       weekly
       rotate 4
       compress
       dateext
       missingok
       notifempty
   }
   ```
   This configuration will rotate the logs weekly, keep the last 4 rotations, and compress old logs.

## Requirements (For duplicacy version)
### Install duplicacy (For duplicacy version)
Official CLI Version: `https://github.com/gilbertchen/duplicacy`


```bash
wget https://github.com/gilbertchen/duplicacy/releases/download/v3.2.2/duplicacy_linux_x64_3.2.2
chmod +x duplicacy_linux_x64_3.2.2
sudo mv duplicacy_linux_x64_3.2.2 /usr/local/bin/duplicacy
duplicacy -version
```


After that initialize it with backup options

### Using Scaleway Free Object Storage (AMS)
```
duplicacy init -storage-name scaleway -repository /root/wpbackup wpbackup s3://nl-ams@s3.nl-ams.scw.cloud/example-bucket-name
duplicacy set -key 's3_id' -value 't3vgg3g3'
duplicacy set -key 's3_secret' -value '3g34g34g43g34g'
```