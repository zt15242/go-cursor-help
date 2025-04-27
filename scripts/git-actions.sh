#!/bin/bash
REPO_DIR="$PWD"
LOCALES_DIR="$REPO_DIR/locales"
msginit -i cursor_id_modifier.pot -o $LOCALES_DIR/en_US/LC_MESSAGES/cursor_id_modifier.po -l en_US
for lang in en_US zh_CN; do
    cd $LOCALES_DIR/$lang/LC_MESSAGES
    msgfmt -o cursor_id_modifier.mo cursor_id_modifier.po
done

