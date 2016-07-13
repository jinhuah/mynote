#/bin/bash
## This file is created for installing MDS server automatically.

if [[ $# -lt 3 ]] 
then
    echo ""
    echo "USAGE: $(basename $0) mds_name git_user git_password"
    echo ""
    echo "mds_name is a name for mds server, it is given by you."
    echo "git_user and git_password is for downloading files from GeniusDigital/workspace-tomw repository."
    echo "Your own git credentials can be used here."
    exit 1
fi

mds_name=$1
git_user=$2
git_password=$3

apt-get update

# Install apache2
apt-get -y install apache2

# Install and enable PHP5
apt-get -y install php5

# Install and enable MOD_SSL and MOD_PHP
a2enmod ssl

# Install and enable mod_headers
a2enmod headers
a2enmod rewrite

# Get files from git repositories
apt-get -y install git
git_dir=$PWD
[[ -d $git_dir/insight-saki  ]] && rm -r $git_dir/insight-saki 
git clone https://$git_user:$git_password@github.com/GeniusDigital/insight-saki
if [[ $? -ne 0 ]]
then
    echo "Check whether your user name and password entered correctly."
    echo "Check whether you have read permission for the repository."
    exit 1
fi

[[ -d $git_dir/workspace-tomw ]] && rm -r $git_dir/workspace-tomw
git clone https://$git_user:$git_password@github.com/GeniusDigital/workspace-tomw
if [[ $? -ne 0 ]]
then
    echo "Check whether your user name and password entered correctly."
    echo "Check whether you have read permission for the repository."
    exit 1
fi

# Copy GD SSL certs to the server into ~/.ssl
if [[ ! -d /home/ubuntu/.ssl ]]
then
    mkdir /home/ubuntu/.ssl
fi

cp $git_dir/insight-saki/biserver/certs/gd-insights-ssl.crt /home/ubuntu/.ssl
cp $git_dir/insight-saki/biserver/certs/gd-insights-ssl.key /home/ubuntu/.ssl
cp $git_dir/insight-saki/biserver/certs/intermediate.crt /home/ubuntu/.ssl

chown -R ubuntu /home/ubuntu/.ssl

# upload profile_db.conf and profile_db_ssl.conf to /etc/apache2/sites-available
cp $git_dir/workspace-tomw/profile-management/profile_db* /etc/apache2/sites-available

# Edit profile_db.conf and profile_db_ssl.conf to point to mds server.
sed -i "s/ServerName astroprofile.geniusdigital.tv:80/ServerName $mds_name.geniusdigital.tv:80/g" /etc/apache2/sites-available/profile_db.conf
sed -i "s/ServerName astroprofile.geniusdigital.tv:443/ServerName $mds_name.geniusdigital.tv:443/g" /etc/apache2/sites-available/profile_db_ssl.conf

# Edit profile_db_ssl.conf to point to GD SSL certs
sed -i "s/SSLCertificateFile \/home\/ubuntu\/gd-insights-ssl.crt/SSLCertificateFile \/home\/ubuntu\/.ssl\/gd-insights-ssl.crt/g" /etc/apache2/sites-available/profile_db_ssl.conf
sed -i "s/SSLCertificateKeyFile \/home\/ubuntu\/gd-insights-ssl.key/SSLCertificateKeyFile \/home\/ubuntu\/.ssl\/gd-insights-ssl.key/g" /etc/apache2/sites-available/profile_db_ssl.conf
sed -i "s/SSLCertificateChainFile \/home\/ubuntu\/intermediate.crt/SSLCertificateChainFile \/home\/ubuntu\/.ssl\/intermediate.crt/g" /etc/apache2/sites-available/profile_db_ssl.conf

# Delete any other files in /var/www/html
rm -rf /var/www/html/*

# Upload notfound.txt .htaccess, upload.php, and admin.php
cp $git_dir/workspace-tomw/profile-management/notfound.txt /var/www/html/
cp $git_dir/workspace-tomw/profile-management/.htaccess /var/www/html/
cp $git_dir/workspace-tomw/profile-management/upload.php /var/www/html/
cp $git_dir/workspace-tomw/profile-management/admin.php /var/www/html/

# Ensure read/write access to /var/www/html for the apache user
chown -R www-data: /var/www/html

# restart apache
service apache2 restart

# enable https site
a2ensite profile_db > /dev/null
a2ensite profile_db_ssl > /dev/null
service apache2 reload

echo "MDS server \"$mds_name\" has been installed. You need to configure DNS server to map this MDS server."