#! /bin/bash

# Provided as an example. The script is deployed by install.sh

exec & >> /var/log/auto_upgrade_wekan.log
URL="https://releases.wekan.team/"
NEW=$(curl -s $URL | grep -e ">wekan.*zip"|sed -r "s/^.*>wekan-(.*?).zip<.*$/\1/"| sort | tail -n 1)
CUR=$(readlink /home/wekan/bundle| cut -d"/" -f 4)
[ "$NEW" == "$CUR" ] && exit 0
[ -e /home/wekan/$NEW ] && exit 0
echo "$(date) Install $NEW"
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
rm -f "/home/wekan/bundle"
ln -s "/home/wekan/$NEW" "/home/wekan/bundle"
supervisorctl restart wekan
echo "$(date) Restarted"

