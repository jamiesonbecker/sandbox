#! /bin/bash

function apt_update {
apt-get update
}

function apt_install {
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -qqy "$@" < /dev/null
}

function configure_figlet_hostname {
    echo "${HOSTNAME}" > /etc/hostname
    hostname "${HOSTNAME}"
    figlet -f small "${HOSTNAME}" > /etc/hostname.figlet
    echo "127.1.1.1 ${HOSTNAME}" >> /etc/hosts
}

function configure_iptables {
    apt_install iptables
    systemctl daemon-reload
    systemctl enable iptables-restore
    systemctl start iptables-restore
}

function configure_ntp {
  sudo apt-get --purge -qqy remove ntp
  apt_install ntp
  mv -vi /etc/ntp.conf.custom /etc/ntp.conf
  systemctl enable ntp
  systemctl start ntp
  ntpd -b time.google.com
}

function configure_ssh_port {
    sudo sed -i "s/[# ]*Port [23]\+/Port $1/g" /etc/ssh/sshd_config
    sudo systemctl restart ssh || sudo systemctl restart sshd
}

function configure_timezone {
    ln -sf /usr/share/zoneinfo/CST6CDT /etc/localtime
}

function install_nginx {
    apt_install nginx
}

function install_node11 {
    set +e; sudo apt-get -qqy --purge remove nodejs; set -e
    curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
    apt_install nodejs
}

function install_node8 {
    set +e; sudo apt-get -qqy --purge remove nodejs; set -e
    curl -sL https://deb.nodesource.com/setup_8.x | bash -
    apt_install nodejs
}

function install_node_utilities {
    sudo npm --global i \
        express-generator \
        pug-cli \
        socketcluster \
        nodemon \

}

function install_redis_server {
    apt_install redis-server
}

function install_userify_shim {
    [ -d /opt/userify ] && /opt/userify/uninstall.sh
	curl -1 -sS "https://wext.userify.com/installer.sh" | \
		api_key="$userify_shim_api_key" \
		api_id="$userify_shim_api_id" \
        company_name="$userify_shim_company_name" \
        project_name="$userify_shim_project_name" \
        static_host="$userify_shim_static_host" \
        shim_host="$userify_shim_shim_host" \
        self_signed=$userify_shim_self_signed \
		sudo -s -E
}

function install_nginx {
    apt_install nginx
}

function install_various_utilities {
    apt_install \
        ntp \
        awscli \
        python-pip \
        screen tmux vim htop iotop \
        python2.7 ipython \
        build-essential \
        figlet \
        rsync \
        vim-haproxy \
        dnsutils \
        whois \
        autossh \

# remove landscape etc on 
# Ubuntu only (not Debian):
set +e
sudo apt-get remove -qqy landscape-client landscape-client-ui landscape-client-ui-install landscape-common
set -e
}

function install_zerotier {
    gpg --import < /opt/makeitso/data/zerotier/zerotier-pgp.pub
    /opt/makeitso/data/zerotier/zerotier_installer.sh
    # zerotier-cli join "$zerotier_network"
}

function standard_install {
    for taskname in \
apt_update \
configure_ntp \
install_zerotier \
configure_timezone \
install_various_utilities \
install_redis_server \
install_node8 \
install_node_utilities \

    do
        echo "Executing $taskname ... "
        if [ "x$taskname" != "x" ]; then
            "$taskname" < /dev/null &> /var/log/install-$taskname.log
        fi
    done
}



