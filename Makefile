BACKUP_DIR ?= backup

GPG_DIRNAME ?= .gnupg
SSH_DIRNAME ?= .ssh

.PHONY: backup
backup:
	mkdir -p $(BACKUP_DIR)/$(GPG_DIRNAME)

	cp -r ~/$(GPG_DIRNAME)/openpgp-revocs.d $(BACKUP_DIR)/$(GPG_DIRNAME)
	cp -r ~/$(GPG_DIRNAME)/private-keys-v1.d $(BACKUP_DIR)/$(GPG_DIRNAME)
	cp ~/$(GPG_DIRNAME)/{gpg.conf,pubring.kbx,trustdb.gpg} $(BACKUP_DIR)/$(GPG_DIRNAME)

	mkdir -p $(BACKUP_DIR)/$(SSH_DIRNAME)

	cp -r ~/$(SSH_DIRNAME) $(BACKUP_DIR)

	tar czf $(BACKUP_DIR).tar.gz $(BACKUP_DIR)

.PHONY: restore
restore:
	tar xzf $(BACKUP_DIR).tar.gz

	# Restore GPG
	cp -r $(BACKUP_DIR)/$(GPG_DIRNAME) ~
	chmod 700 ~/$(GPG_DIRNAME)
	chmod 700 ~/$(GPG_DIRNAME)/openpgp-revocs.d
	chmod 700 ~/$(GPG_DIRNAME)/private-keys-v1.d
	chmod 600 ~/$(GPG_DIRNAME)/private-keys-v1.d/*
	chmod 600 ~/$(GPG_DIRNAME)/gpg.conf
	chmod 600 ~/$(GPG_DIRNAME)/pubring.kbx
	chmod 600 ~/$(GPG_DIRNAME)/trustdb.gpg

	# Restore SSH
	cp -r $(BACKUP_DIR)/$(SSH_DIRNAME) ~
	chmod 700 ~/$(SSH_DIRNAME)
	chmod 600 ~/$(SSH_DIRNAME)/id_* ~/$(SSH_DIRNAME)/google_* 2>/dev/null || true
	chmod 644 ~/$(SSH_DIRNAME)/*.pub 2>/dev/null || true
	chmod 600 ~/$(SSH_DIRNAME)/config 2>/dev/null || true
