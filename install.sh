#! /bin/bash
# @author   alban
# @since    2019-09-06
# @url      https://git.interhacker.space/alban/wekan-bash-installer

MSG="Please provide the domain name you want to host wekan on [Default:localhost] : "
read -p "$MSG" DOMAIN
DOMAIN=${DOMAIN:-localhost}

MSG="Please provide the email address for wekan service mails [Default:wekan@${DOMAIN}] : "
read -p "$MSG" EMAIL
DEFAULT_EMAIL="wekan@$DOMAIN"
EMAIL=${EMAIL:-$DEFAULT_EMAIL}

[ "$DOMAIN" != "localhost" ] && {
  MSG="Do you want to deploy an HTTPS vhost for wekan? [Y/n]"
  read -p "$MSG"
  REPLY=${REPLY:-Y}
  SSL=$( [ "${REPLY^^}" == "Y" ] && echo "yes" || echo "no" )

}

################################################################################
# You MIGHT change the following variables depending on your situation
################################################################################

# Which nodejs do you wish to install
NODEREPO="node_12.x"


################################################################################
# After that, you should not need to edit anything below.
# But hack at leisure ;)
################################################################################

# This script will only work on Debian 9 "Stretch"
DISTRO="stretch"

# Helper functions
ops=0
Lets(){ let $(( ops++ )); echo -e "\n# ${ops}: $@\n"; }
Red(){ echo -e "\033[0;31m$@\033[0m"; }

# Now comments will be noted by "^Lets" lines, see next line as an example
Lets install required packages for basic APT operations
apt update
apt install -y apt-transport-https curl gnupg

Lets install the nodejs repository
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/${NODEREPO} ${DISTRO} main" > /etc/apt/sources.list.d/$NODEREPO.list

Lets install application packages and set the services auto up
apt update
apt install -y nodejs mongodb mongodb-server git nginx npm supervisor certbot make g++ unzip
for f in mongodb nginx supervisor ; do systemctl enable $f; done

dpkg -l postfix | grep -q -E "^.i +postfix" || {

  Lets install and configure the email service
  Red Caution! Please choose the  \"Internet Site\" option when requested!
  apt install -y postfix

  Lets configure Postfix to run on local loopback only
  postconf -e 'inet_interfaces = 127.0.0.1'
  service postfix restart

}

if [ $SSL == "yes" ] ; then

  Lets create the nginx HTTP virtual host
cat << HEREDOC > /etc/nginx/sites-available/wekan.conf
# nginx configuration for wekan proxying

# this section is needed to proxy web-socket connections
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}
server {
  listen 80;
  server_name $DOMAIN;
  large_client_header_buffers 8 64k;
  client_header_buffer_size 64k;
  location .well-known/acme-challenge {
    root /var/www/letsencrypt;
  }
  location / {
    return 301 https://\$host\$request_uri;
  }
}
HEREDOC
  [ -L /etc/nginx/sites-enabled/wekan.conf ] || ln -s ../sites-available/wekan.conf /etc/nginx/sites-enabled/wekan.conf

  Lets reload nginx
  nginx -t && service nginx reload

  Lets request the certificate from Letsencrypt
  mkdir -p /var/www/letsencrypt/.well-known/acme-challenge
  echo "test $(hostname) OK" > /var/www/letsencrypt/.well-known/acme-challenge/test.txt
  chown -R www-data:www-data /var/www/letsencrypt
  curl http://$DOMAIN/.well-known/acme-challenge/test.txt && \
  certbot certonly --webroot --agree-tos -w /var/www/letsencrypt/ --email certs@$DOMAIN -d $DOMAIN

  Lets create the HTTPS virtual host
cat << HEREDOC >> /etc/nginx/sites-available/wekan.conf
server {
  listen 443 http2;
  server_name $DOMAIN;
  large_client_header_buffers 8 64k;
  client_header_buffer_size 64k;
  ssl on;
  ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.1 TLSv1;

  # If your application is not compatible with IE <= 10, this will redirect visitors to a page advising a browser update
  # This works because IE 11 does not present itself as MSIE anymore
  if (\$http_user_agent ~ "MSIE" ) {
      return 303 https://browser-update.org/update.html;
  }

  # Pass requests to Wekan.
  # If you have Wekan at https://example.com/wekan , change location to:
  # location /wekan {
  location / {
      proxy_pass http://127.0.0.1:8080;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade; # allow websockets
      proxy_set_header Connection \$connection_upgrade;
      proxy_set_header X-Forwarded-For \$remote_addr; # preserve client IP

      # this setting allows the browser to cache the application in a way compatible with Meteor
      # on every applicaiton update the name of CSS and JS file is different, so they can be cache infinitely (here: 30 days)
      # the root path (/) MUST NOT be cached
      if (\$uri != '/wekan') {
          expires 30d;
      }
  }

}
HEREDOC

  Lets reload nginx to handle HTTPS
  nginx -t && service nginx restart
else

  Lets create the nginx HTTP virtual host
cat << HEREDOC > /etc/nginx/sites-available/wekan.conf
# nginx configuration for wekan proxying

# this section is needed to proxy web-socket connections
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}
server {
  listen 80;
  server_name $DOMAIN;
  large_client_header_buffers 8 64k;
  client_header_buffer_size 64k;
  location .well-known/acme-challenge {
    root /var/www/letsencrypt;
  }

  # If your application is not compatible with IE <= 10, this will redirect visitors to a page advising a browser update
  # This works because IE 11 does not present itself as MSIE anymore
  if (\$http_user_agent ~ "MSIE" ) {
      return 303 https://browser-update.org/update.html;
  }

  # Pass requests to Wekan.
  # If you have Wekan at https://example.com/wekan , change location to:
  # location /wekan {
  location / {
      proxy_pass http://127.0.0.1:8080;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade; # allow websockets
      proxy_set_header Connection \$connection_upgrade;
      proxy_set_header X-Forwarded-For \$remote_addr; # preserve client IP

      # this setting allows the browser to cache the application in a way compatible with Meteor
      # on every applicaiton update the name of CSS and JS file is different, so they can be cache infinitely (here: 30 days)
      # the root path (/) MUST NOT be cached
      if (\$uri != '/wekan') {
          expires 30d;
      }
  }
}
HEREDOC

fi

Lets create the supervisor configuration
mkdir /var/log/wekan
ROOT_URL=$( [ $SSL == "yes" ] && echo "https://$DOMAIN" || echo "http://$DOMAIN")

cat << HEREDOC > /etc/supervisor/conf.d/wekan.conf
[program:wekan]
command=/usr/bin/node main.js
process_name=%(program_name)s
numprocs=1
directory=/home/wekan/bundle
umask=022
priority=999
autostart=true
startsecs=1
startretries=3
autorestart=unexpected
exitcodes=0,2
stopsignal=QUIT
stopwaitsecs=10
stopasgroup=false
killasgroup=false
user=wekan
redirect_stderr=false
stdout_logfile=/var/log/wekan/out.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
stdout_events_enabled=false
stderr_logfile=/var/log/wekan/err.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
stderr_events_enabled=false
environment=MONGO_URL='mongodb://127.0.0.1:27017/wekan',ROOT_URL='$ROOT_URL',MAIL_URL='smtp://localhost:25/',MAIL_FROM='$EMAIL',PORT=8080,BIND_IP=127.0.0.1,HTTP_FORWARDED_COUNT=1
serverurl=AUTO
HEREDOC

Lets create the auto upgrade script
cat << HEREDOC > /usr/local/sbin/auto_upgrade_wekan
#! /bin/bash
exec & >> /var/log/auto_upgrade_wekan.log
URL="https://releases.wekan.team/"
NEW=\$(curl -s \$URL | grep -e ">wekan.*zip"|sed -r "s/^.*>wekan-(.*?).zip<.*\$/\1/"| sort | tail -n 1)
CUR=\$(readlink /home/wekan/bundle| cut -d"/" -f 4)
[ "\$NEW" == "\$CUR" ] && exit 0
[ -e /home/wekan/\$NEW ] && exit 0
echo "\$(date) Install \$NEW"
TMP=\$( mktemp -d )
cd "\$TMP"
wget --quiet "\$URL/wekan-\$NEW.zip"
unzip "wekan-\$NEW.zip" &>/dev/null
mv bundle "/home/wekan/\$NEW"
cd "/home/wekan/\$NEW/programs/server"
npm uninstall fibers
npm install fibers
chown -R wekan:wekan "/home/wekan/\$NEW"
rm -rf "\$TMP"
rm -f "/home/wekan/bundle"
ln -s "/home/wekan/\$NEW" "/home/wekan/bundle"
supervisorctl restart wekan
echo "\$(date) Restarted"
HEREDOC
chmod +x /usr/local/sbin/auto_upgrade_wekan
cat << HEREDOC > /etc/cron.d/auto_upgrade_wekan
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin/:/usr/local/bin/
0 0 * * * root /usr/local/sbin/auto_upgrade_wekan
HEREDOC

Lets add a wekan user
adduser --disabled-password --gecos "" wekan

Lets download the latest bundle
URL="https://releases.wekan.team/"
NEW=$(curl -s $URL | grep -e ">wekan.*zip"|sed -r "s/^.*>wekan-(.*?).zip<.*$/\1/"| sort | tail -n 1)
TMP=$( mktemp -d )
cd "$TMP"
wget --quiet "$URL/wekan-$NEW.zip"
unzip "wekan-$NEW.zip" &>/dev/null
mv bundle "/home/wekan/$NEW"
cd "/home/wekan/$NEW/programs/server"
npm uninstall fibers
npm install fibers
chown -R wekan:wekan "/home/wekan/$NEW"
rm -rf "$TMP"
ln -s "/home/wekan/$NEW" "/home/wekan/bundle"

Lets reload supervisor
supervisorctl reread
supervisorctl update
