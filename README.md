# Wekan BASH Installer

## Why using this script?

If like me, you want to run Wekan on Debian and the [install options](https://github.com/wekan/wekan/wiki/Platforms) don't fit your model.

**Debian 9 Stretch images required for this script to work**

It won't work on Debian 10 Buster, little story about that below if you're interested.

## Crash course


`curl https://git.interhacker.space/alban/wekan-bash-installer/raw/branch/master/install.sh | bash`

Pretty simple if you're into `curl|bash` methods ;) Otherwise feel free to `git clone`, `wget`, or use the method of your liking to download and execute.


## How it works

**The script will install the following assets**

* Wekan
* NodeJS
* MongoDB
* Nginx
* Letsencrypt
* Supervisor
* Postfix
* Wekan auto updater

**Notes**

* Wekan runs on localhost port 8080
* Nginx acts as a reverse proxy for Wekan
* Letsencrypt is used to provide HTTPS
* Supervisor provides the daemonization of the process
* Postfix runs on localhost to send emails, if not configured previously
* The Wekan auto updater cron will check new bundles, install them, and reload the service
* You can configure in the script the NodeJS version of your choice
* NodeJS is installed from the NodeSource repository



## Words of Caution

### HTTPS and $DOMAIN

If you want an HTTPS vhost, better add your domain to the DNS.

Or Letsencrypt won't be able to verify your domain and you will get no certificate.

#### Backups

There's no mongodb backup automatically configured. Please don't run this in production without a data backup plan.

## Bugs, contribution

All are welcome.

Please send an email to wekan@albancrommer.com in case of an emergency.

## Why Debian 9 only?

Ah, well, you're reading, hey? Here's our little story.

Some day, mongodb decided it should change its licensing, and since it was restricting the freedom of its users Debian to remove mongodb packages from its new repositories.

Installing mongodb on Debian 10 «Buster» is a mess, and it doesn't look like mongodb has made any move to fix it.

So meanwhile, you're better off running
