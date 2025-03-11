#!/bin/bash

OUTPUT_FILE=$(mktemp)

{
    echo "=== Systémové informace ==="
    lsb_release -a 2>/dev/null || echo "Distribuce nezjištěna"
    uname -a
    echo ""

    echo "=== Verze desktopového prostředí ==="
    if command -v cinnamon --version &>/dev/null; then
        cinnamon --version
    elif command -v mate-about --version &>/dev/null; then
        mate-about --version
    else
        echo "Verzi desktopového prostředí se nepodařilo zjistit"
    fi
    echo ""

    echo "=== Informace o aktualizacích ==="
    if command -v apt &>/dev/null; then
        echo "Počet dostupných aktualizací:"
        apt list --upgradable 2>/dev/null | wc -l
        echo "Poslední aktualizace systému:"
        ls -lct /var/log/apt/history.log | awk '{print $6, $7, $8}'
    else
        echo "Systém nepoužívá APT, nelze zjistit stav aktualizací"
    fi
    echo ""

    echo "=== Verze prohlížečů ==="
    if command -v firefox &>/dev/null; then
        firefox --version
    else
        echo "Firefox není nainstalován"
    fi
    if command -v chromium-browser &>/dev/null; then
        chromium-browser --version
    elif command -v chromium &>/dev/null; then
        chromium --version
    else
        echo "Chromium není nainstalován"
    fi
    echo ""

    echo "=== Připojené USB disky ==="
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -i usb || echo "Žádné USB disky nenalezeny"
    echo ""

    echo "=== Volné místo na disku ==="
    df -h /
    echo ""

    echo "=== Nainstalované důležité balíčky ==="
    dpkg -l | grep -E "linux-image|linux-headers|xorg|cinnamon|mate-desktop|firefox|chromium"
    echo ""

    echo "=== Poslední reboot systému ==="
    who -b
    echo ""

    echo "=== Stav automatických aktualizací ==="
    if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
        cat /etc/apt/apt.conf.d/20auto-upgrades
    else
        echo "Soubor pro automatické aktualizace nenalezen"
    fi

} > "$OUTPUT_FILE"

# Upload na Pastebin pomocí curl (bez registrace)
PASTEBIN_URL=$(curl -s -F 'file=@'"$OUTPUT_FILE" https://paste.rs)

# Výstup odkazu a instrukce pro uživatele
echo ""
echo "=== Odkaz na výstup ==="
echo "$PASTEBIN_URL"
echo ""
echo "Zkopírujte tento odkaz a pošlete ho spolu se screenshotem tohoto terminálu."
