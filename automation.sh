sudo apt update -y

apache="install"

if [[ $apache != $(dpkg --get-selections apache2 | awk '{print $1}') ]]
then
	echo "Here"
	sudo apt install apache2 -y
fi

service='running'
if [[ $service != $(systemctl status apache2 | grep active | awk '{print $3}' | tr -d '()' ) ]]
then 
	sudo systemctl start apache2
fi

if [[ "enable" != $(systemctl is-enabled apache2 | grep "enabled") ]]
then
	sudo systemctl enable apache2
fi

name="Parikshit"
timestamp=$(date '+%d%m%Y-%H%M%S')
cd /var/log/apache2
sudo tar -cf /tmp/${name}-httpd-logs-${timestamp}.tar *.log

s3_bucket=”upgradparikshit”

if [[ -f/tmp/${name}-httpd-logs-${timestamp}.tar ]]
then
	aws s3 \
	cp /tmp/${name}-httpd-logs-${timestamp}.tar \
	s3://${s3_bucket}/${name}-httpd-logs-${timestamp}.tar
fi


docroot="/var/www/html"
if [[ ! -f ${docroot}/inventory.html ]]; then
	echo -e 'Log Type\t-\tTime Created\t-\tType\t-\tSize' >  ${docroot}/inventory.html
fi

if [[ -f ${docroot}/inventory.html ]]; then
	size=$(du -h /tmp/${name}-httpd-logs-${timestamp}.tar | awk '{print $1}')
	echo -e \n"httpd-logs\t-\t${timestamp}\t-\ttar\t-\t${size}" >> ${docroot}/inventory.html
fi

if [[ ! -f /etc/cron.d/automation ]]; then
	echo "* * * * * root /root/automation.sh" >> /etc/cron.d/automation
fi
