# Axelor installer for Debian 8 Jessie

[Axelor](https://www.axelor.com) is a fully modular, user-friendly and scalable Open Source ERP


## Requirements:

* A fresh installed Debian Jessie
* Also set-up network properly

## Install:

Execute the following shell command as root user:

```bash
wget --no-check-certificate -O - https://github.com/lspg/debian-scripts/raw/master/axelor/axelor-debian8-install.sh | bash
```

## Advanced Install:

Get the script:

```bash
wget --no-check-certificate -O /tmp/axelor-debian8-install.sh https://github.com/lspg/debian-scripts/raw/master/axelor/axelor-debian8-install.sh
```

Open it with your favorite text editor and modify environments variables to fit your needs:

```bash
nano /tmp/axelor-debian8-install.sh
```

Launch it:

```bash
bash /tmp/axelor-debian8-install.sh
```

## Usage:

At the end of the script, the tomcat server will start the app, this part can be quite long (a few minutes, depending on your system's specs).
The script will tail the tomcat log so you can have an eye on that process.
Wait until you read "Server started in XXXXXXXXs".
Then go to another computer on same lan and browse http://<AXELOR_IP>:8080
