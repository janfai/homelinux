#!/bin/bash

# Název: Aktualizace konfigurace Postfix
# Popis: Tento skript aktualizuje konfiguraci Postfixu, včetně nastavení relay hosta
#        a přihlašovacích údajů. Také aktualizuje e-mailovou adresu v /etc/aliases.
#        Po provedení změn ověří úspěšnost aktualizace a odešle výsledek na zadaný e-mail.
#
# Použití: Tento skript lze stáhnout a spustit jedním příkazem:
#   curl -sSL https://raw.githubusercontent.com/janfai/postfix_satellite/main/wks_update_postfix.sh | sudo bash
#
# Poznámka: Ujistěte se, že spouštíte příkaz s právy sudo.

# Nastavení proměnných
ADMIN_EMAIL="jan@faix.cz"
PASSWORD_URL="https://pwpush.com/p/xwuy1igqcmruehh5"
RELAY_HOST="mail.faix.cz"
USERNAME="mail@faix.cz"
OLD_EMAIL="jan.faix@gmail.com"
NEW_EMAIL="jan@faix.cz"

# Kontrola a instalace curl a mutt
for cmd in curl mutt; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd není nainstalován. Instaluji..."
        sudo apt-get update && sudo apt-get install -y $cmd
    fi
done

# Stažení hesla z pwpush.com
PASSWORD=$(curl -sSL "$PASSWORD_URL" | grep -o '<div id="text_payload".*</div>' | sed -E 's/.*>([^<]+)<.*/\1/')

# Aktualizace souboru relay_passwd
echo "[$RELAY_HOST]:587 $USERNAME:$PASSWORD" | sudo tee /etc/postfix/relay_passwd > /dev/null

# Vytvoření databáze
sudo postmap /etc/postfix/relay_passwd

# Aktualizace main.cf
sudo postconf -e "relayhost = [$RELAY_HOST]:587"
sudo postconf -e "smtp_use_tls = yes"
sudo postconf -e "smtp_sasl_auth_enable = yes"
sudo postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/relay_passwd"
sudo postconf -e "smtp_sasl_security_options = noanonymous"

# Aktualizace e-mailu v /etc/aliases
sudo sed -i "s/$OLD_EMAIL/$NEW_EMAIL/g" /etc/aliases

# Aktualizace databáze aliasů
sudo newaliases

# Restart Postfixu
sudo systemctl restart postfix

# Funkce pro ověření změny
check_relay_passwd() {
    if grep -q "$USERNAME" /etc/postfix/relay_passwd; then
        return 0
    else
        return 1
    fi
}

# Funkce pro ověření změny e-mailu v aliases
check_aliases() {
    if grep -q "$NEW_EMAIL" /etc/aliases; then
        return 0
    else
        return 1
    fi
}

# Funkce pro odeslání výsledku emailem
send_result_email() {
    local subject="Výsledek změny konfigurace Postfixu"
    local body="$1"
    echo "$body" | mutt -s "$subject" $ADMIN_EMAIL
}

# Ověření změn a odeslání výsledku
if check_relay_passwd && check_aliases; then
    send_result_email "Změna konfigurace Postfixu a aktualizace aliases byly úspěšné."
    echo "Přihlašovací údaje pro Postfix a aliases byly úspěšně aktualizovány."
else
    send_result_email "Změna konfigurace Postfixu nebo aktualizace aliases nebyla úspěšná."
    echo "Chyba: Aktualizace konfigurace Postfixu nebo aliases se nezdařila."
fi
