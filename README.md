# wpbackup
Simple shell script to backup WordPress sites installed by WordOps with Duplicacy. By default WordOps puts `wp-config.php` in each sites root folder, if this is not the case then remove the relevant lines that check for it existence.

## Install duplicacy
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
