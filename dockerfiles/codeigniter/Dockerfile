FROM ubuntu:15.10

ENV DEBIAN_FRONTEND noninteractive

# Ensure UTF-8
RUN locale-gen en_AU.UTF-8
ENV LANG       en_AU.UTF-8
ENV LC_ALL     en_AU.UTF-8

# Start by adding/updating required software
RUN apt-get update
RUN apt-get -y install python-software-properties software-properties-common

# Enable the PHP 7 PPA
RUN apt-add-repository -y ppa:ondrej/php-7.0

# Update again now with the extra repos
RUN apt-get update
RUN apt-get -y dist-upgrade

# Install new packages we need
RUN apt-get -y install apache2

# Install robo
RUN wget -O /usr/local/bin/robo http://robo.li/robo.phar && chmod +x /usr/local/bin/robo

# Install composer
RUN wget -q https://getcomposer.org/installer -O - | php -- --install-dir=/usr/local/bin --filename=composer


# XDEBUG
# Find host ip, then setup xdebug
RUN HOST=$(ip -4 route show default | grep -Po 'default via \K[\d.]+') && echo "; configuration for php xdebug module\n; priority=20\nzend_extension=xdebug.so\nxdebug.max_nesting_level=500\nxdebug.remote_enable=1\nxdebug.remote_port=9001\nxdebug.remote_host=${HOST}\nxdebug.remote_autostart=1\nxdebug.idekey=PHPSTORM" > /etc/php/mods-available/xdebug.ini
RUN phpenmod -v ALL -s ALL xdebug

# Add smtp support
RUN apt-get -y install ssmtp
RUN echo "sendmail_path = /usr/sbin/ssmtp -t" > /etc/php/mods-available/sendmail.ini
RUN echo "mailhub=mail:25\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf
RUN phpenmod -v ALL -s ALL sendmail

# Install packages
RUN apt-get -y install php7.0 php7.0-cli php7.0-common libapache2-mod-php7.0 php-apcu php7.0-curl php7.0-gd php7.0-ldap php7.0-mysql php7.0-opcache php-xdebug libedit-dev vim wget curl ssh mysql-client netcat-openbsd sudo

# Configure timezone
RUN echo "Australia/Adelaide" > /etc/timezone; dpkg-reconfigure tzdata

RUN chmod +x /usr/local/bin/apache2-foreground
RUN a2dissite 000-default

RUN apt-get -y autoclean
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Ports
EXPOSE 80 443

# set working directory.
WORKDIR /web

CMD ["/usr/local/bin/apache2-foreground"]