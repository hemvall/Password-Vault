#!/bin/bash

VAULT_FILE=".vault.gpg"
TEMP_FILE="vault_temp.txt"
LOG_FILE="vault_access.log"

# Fonction pour supprimer temp même si crash ou ctrl+c
function clean_up {
    rm -f "$TEMP_FILE"
    exit
}
trap clean_up INT TERM EXIT

# Crée un fichier vide chiffré si inexistant
if [[ ! -f "$VAULT_FILE" ]]; then
    whiptail --msgbox "Aucun coffre trouvé. Il va être créé." 8 40
    touch "$TEMP_FILE"
    gpg --yes --batch --symmetric --output "$VAULT_FILE" "$TEMP_FILE"
    rm -f "$TEMP_FILE"
fi

# Déchiffre le vault dans un fichier temporaire
gpg --quiet --decrypt "$VAULT_FILE" > "$TEMP_FILE" 2>/dev/null

while true; do
    CHOICE=$(whiptail --title "🔐 Coffre de mots de passe" \
    --backtitle "		🟢 Secure CLI Vault - Entièrement local & chiffré avec GPG" \
     --menu "Que veux-tu faire ?" 15 50 4 \
    "1" "Ajouter un mot de passe" \
    "2" "Voir un mot de passe" \
    "3" "Quitter" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1)
            service=$(whiptail --inputbox "Nom du service ?" 8 40 --title "Ajout" 3>&1 1>&2 2>&3) || continue
            username=$(whiptail --inputbox "Identifiant ?" 8 40 3>&1 1>&2 2>&3) || continue
            password=$(whiptail --passwordbox "Mot de passe ?" 8 40 3>&1 1>&2 2>&3) || continue
            echo "$service:$username:$password" >> "$TEMP_FILE"
            whiptail --msgbox "Ajouté avec succès." 7 40
            ;;
        2)
	    service=$(whiptail --inputbox "Service à consulter ?" 8 50 3>&1 1>&2 2>&3) || continue
	    result=$(grep "^$service:" "$TEMP_FILE")
	    if [[ -n "$result" ]]; then
		IFS=':' read -r s u p <<< "$result"
		echo "$(date '+%Y-%m-%d %H:%M:%S') - ACCÈS à '$service' par utilisateur '$u'" >> "$LOG_FILE"
		echo -n "$p" | xclip -selection clipboard
		whiptail --title "🔎 Résultat" --msgbox "Identifiant : $u\nMot de passe copié dans le presse-papier ✅" 10 60
	    else
		whiptail --title "❌ Introuvable" --msgbox "Aucun mot de passe trouvé pour $service." 8 50
	    fi
	    ;;
        3)
            break
            ;;
        *)
            continue
            ;;
    esac
done

# Rechiffre le fichier
gpg --yes --batch --symmetric --output "$VAULT_FILE" "$TEMP_FILE"

# Nettoyage géré automatiquement via trap
exit 0
