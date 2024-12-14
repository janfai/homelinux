#!/bin/bash

# Název: Aktualizace konfigurace OSSEC
# Popis: Tento skript aktualizuje konfiguraci OSSEC v souboru ossec.conf,
#        včetně nastavení e-mailových notifikací a SMTP serveru.
#        Po provedení změn ověří úspěšnost aktualizace a odešle výsledek na zadaný e-mail.
#
# Použití: Tento skript lze stáhnout a spustit jedním příkazem:
#   curl -sSL https://example.com/update_ossec.sh | sudo bash
#
# Poznámka: Ujistěte se, že spouštíte příkaz s právy sudo.

# Nastavení proměnných
ADMIN_EMAIL="jan@faix.cz"
OSSEC_CONF="/var/ossec/etc/ossec.conf"
MAILNAME_FILE="/etc/mailname"

# Kontrola a instalace mutt
if ! command -v mutt &> /dev/null; then
    echo "mutt není nainstalován. Instaluji..."
    sudo apt-get update && sudo apt-get install -y mutt
fi

# Získání domény z /etc/mailname
DOMAIN=$(cat $MAILNAME_FILE)

# Funkce pro aktualizaci ossec.conf
update_ossec_conf() {
    sudo sed -i '/<global>/,/<\/global>/c\
  <global>\
    <email_notification>yes</email_notification>\
    <email_to>root.faix@faix.cz</email_to>\
    <smtp_server>127.0.0.1</smtp_server>\
    <email_from>ossec@'"$DOMAIN"'</email_from>\
  </global>' $OSSEC_CONF
}

# Funkce pro ověření změny
check_ossec_conf() {
    if grep -q "<email_from>ossec@$DOMAIN</email_from>" $OSSEC_CONF; then
        return 0
    else
        return 1
    fi
}

# Funkce pro odeslání výsledku emailem
send_result_email() {
    local subject="Výsledek změny konfigurace OSSEC"
    local body="$1"
    echo "$body" | mutt -s "$subject" $ADMIN_EMAIL
}

# Provedení aktualizace
update_ossec_conf

# Ověření změn a odeslání výsledku
if check_ossec_conf; then
    send_result_email "Změna konfigurace OSSEC byla úspěšná. E-mail odesílatele nastaven na ossec@$DOMAIN."
    echo "Konfigurace OSSEC byla úspěšně aktualizována."
else
    send_result_email "Změna konfigurace OSSEC nebyla úspěšná."
    echo "Chyba: Aktualizace konfigurace OSSEC se nezdařila."
fi

# Restart OSSEC pro aplikaci změn
sudo /var/ossec/bin/ossec-control restart
