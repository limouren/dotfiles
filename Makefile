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
