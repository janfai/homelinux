#!/bin/bash

# Název: Aktualizace e-mailu v .bashrc
# Popis: Tento skript aktualizuje e-mailovou adresu v souboru /root/.bashrc na 'root'
#        v řádku s upozorněním na přístup roota.
#        Po provedení změn ověří úspěšnost aktualizace a odešle výsledek na zadaný e-mail.
#
# Použití: Tento skript lze stáhnout a spustit jedním příkazem:
#   curl -sSL https://raw.githubusercontent.com/janfai/homelinux/main/root_alert.sh | sudo bash
#
# Poznámka: Ujistěte se, že spouštíte příkaz s právy sudo.

# Nastavení proměnných
ADMIN_EMAIL="jan@faix.cz"
BASHRC_FILE="/root/.bashrc"
NEW_EMAIL="root"

# Kontrola a instalace mutt
if ! command -v mutt &> /dev/null; then
    echo "mutt není nainstalován. Instaluji..."
    sudo apt-get update && sudo apt-get install -y mutt
fi

# Funkce pro aktualizaci .bashrc
update_bashrc() {
    # Nahradí 'mail' za 'mutt' a jakoukoliv e-mailovou adresu za 'root'
    sudo sed -i '/ALERT.*Root Shell Access/s/mail/mutt/g; /ALERT.*Root Shell Access/s/[A-Za-z0-9._%+-]\+@[A-Za-z0-9.-]\+\.[A-Z|a-z]\{2,\}/root/g' "$BASHRC_FILE"
}

# Funkce pro ověření změny
check_bashrc() {
    if grep -q "echo.*| mutt -s \"Alert: Root Access from.*\" root" "$BASHRC_FILE"; then
        return 0
    else
        return 1
    fi
}

# Funkce pro odeslání výsledku emailem
send_result_email() {
    local subject="Výsledek změny e-mailu a příkazu v .bashrc"
    local body="$1"
    echo "$body" | mutt -s "$subject" "$ADMIN_EMAIL"
}

# Provedení aktualizace
update_bashrc

# Ověření změn a odeslání výsledku
if check_bashrc; then
    send_result_email "Změna e-mailu a příkazu v .bashrc byla úspěšná. E-mail byl nastaven na '$NEW_EMAIL' a příkaz byl změněn na 'mutt'."
    echo "E-mail a příkaz v .bashrc byly úspěšně aktualizovány."
else
    send_result_email "Změna e-mailu a příkazu v .bashrc nebyla úspěšná."
    echo "Chyba: Aktualizace e-mailu a příkazu v .bashrc se nezdařila."
fi

# Aplikace změn v aktuální relaci
source "$BASHRC_FILE"
