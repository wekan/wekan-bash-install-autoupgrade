# Wekan BASH Installer

## Why using this script?

If like me, you want to run Wekan on Debian and the [install options](https://github.com/wekan/wekan/wiki/Platforms) don't fit your model.


**Please use it on a Debian 9 Stretch image.**


It won't work on Debian 10 Buster, little story about that below if you're interested.

## Crash course


`curl -s https://raw.githubusercontent.com/wekan/wekan-bash-install-autoupgrade/master/install.sh | bash`

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

#### HTTPS and $DOMAIN

If you want an HTTPS vhost, better add your domain to the DNS.

Or Letsencrypt won't be able to verify your domain and you will get no certificate.

#### Backups

There's no mongodb backup automatically configured. Please don't run this in production without a data backup plan.

## Bugs, contribution

All are welcome.

Please send an email to wekan@albancrommer.com in case of an emergency.

## Why Debian 9 only?

Ah, well, you're reading, hey? Here's our little story.

Once upon a time, everything was beautiful. 

The sun shined, baby seals were killed by thousands, it was easy to install Wekan, and patriarchy gladly ruled the world.

But then one day, some mongodb Gods In The Sky decided they should change the software's licensing.

Turns out it was restricting the freedom of users.

It didn't take long for the Debian Knights of the White Keyboard to react. 

They steadily removed all mongodb packages from new repositories starting with the release of Buster.

The poor people were miserable. 

Well, they were miserable already but now installing mongodb on Debian 10 «Buster» was a mess.

The mongodb Gods did not see fit to fix it, probably because that meant selling more Cloud installs which they fed upon.

And here it is childs, you've got to run Wekan on Stretch because the upper management got messy. 

Now get back to work, you peons.
