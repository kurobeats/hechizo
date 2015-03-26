
all:
	$(MAKE) -C hostapd-manna/hostapd/

install:
	# Create the target directories
	install -d -m 755 $(DESTDIR)/usr/share/hechizo/www
	install -d -m 755 $(DESTDIR)/usr/share/hechizo/crackapd
	install -d -m 755 $(DESTDIR)/usr/share/hechizo/firelamb
	install -d -m 755 $(DESTDIR)/usr/share/hechizo/sslstrip-hsts/sslstrip
	install -d -m 755 $(DESTDIR)/usr/share/hechizo/cert
	install -d -m 755 $(DESTDIR)/usr/share/hechizo/scripts
	install -d -m 755 $(DESTDIR)/usr/lib/hechizo/
	install -d -m 755 $(DESTDIR)/var/lib/hechizo/sslsplit
	install -d -m 755 $(DESTDIR)/etc/hechizo/
	install -d -m 755 $(DESTDIR)/etc/stunnel/
	install -d -m 755 $(DESTDIR)/etc/apache2/sites-available/
	# Install configuration files
	install -m 644 scripts/conf/* $(DESTDIR)/etc/hechizo/
	install -m 644 crackapd/crackapd.conf $(DESTDIR)/etc/hechizo/
	install -m 644 apache/etc/apache2/sites-available/* $(DESTDIR)/etc/apache2/sites-available/
	# Install the stunnel configuration we want
	install -m 644 apache/etc/stunnel/stunnel.conf $(DESTDIR)/etc/stunnel/hechizo.conf
	# Install the hostapd binary
	install -m 755 hostapd-manna/hostapd/hostapd $(DESTDIR)/usr/lib/hechizo/
	install -m 755 hostapd-manna/hostapd/hostapd_cli $(DESTDIR)/usr/lib/hechizo/
	# Install the data
	cp -R apache/var/www/* $(DESTDIR)/usr/share/hechizo/www/
	install -m 644 scripts/cert/* $(DESTDIR)/usr/share/hechizo/cert/
	# Install the scripts
	install -m 755 crackapd/crackapd.py $(DESTDIR)/usr/share/hechizo/crackapd/
	install -m 644 firelamb/* $(DESTDIR)/usr/share/hechizo/firelamb/
	chmod 755 $(DESTDIR)/usr/share/hechizo/firelamb/*.py \
	          $(DESTDIR)/usr/share/hechizo/firelamb/*.sh
	install -m 644 sslstrip-hsts/sslstrip/* \
	    $(DESTDIR)/usr/share/hechizo/sslstrip-hsts/sslstrip/
	install -m 644 $$(find sslstrip-hsts/ -maxdepth 1 -type f) \
	    $(DESTDIR)/usr/share/hechizo/sslstrip-hsts/
	chmod 755 $(DESTDIR)/usr/share/hechizo/sslstrip-hsts/sslstrip.py \
	          $(DESTDIR)/usr/share/hechizo/sslstrip-hsts/dns2proxy.py
	install -m 755 scripts/*.sh $(DESTDIR)/usr/share/hechizo/scripts
	# Dynamic configuration (if not fake install)
	if [ "$(DESTDIR)" = "" ]; then \
	    if [ -e /etc/default/stunnel4 ]; then \
	        sed -i -e 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4; \
	    fi; \
	    a2enmod rewrite || true; \
	    for conf in apache/etc/apache2/sites-available/*; do \
	        a2ensite `basename $$conf` || true; \
	    done; \
	fi
