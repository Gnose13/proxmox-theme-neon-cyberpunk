#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#
#   ████████╗██╗  ██╗███████╗███╗   ███╗███████╗
#   ╚══██╔══╝██║  ██║██╔════╝████╗ ████║██╔════╝
#      ██║   ███████║█████╗  ██╔████╔██║█████╗
#      ██║   ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══╝
#      ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗
#      ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝
#
#   PROXMOX VE — THÈME CYBERPUNK BLEU NÉON (version portable)
#
# ═══════════════════════════════════════════════════════════════════
#
# Nom          : install_theme_proxmox.sh
# Description  : Thème d'interface cyberpunk bleu néon pour Proxmox VE :
#                fond animé, icônes colorées par type (VM, LXC, modèles,
#                nœuds, datacenter), effets néon, menus, fenêtres,
#                infobulles, barres de progression, badge d'établissement.
#                Options pédagogiques facultatives : message d'accueil
#                après connexion, « clone intégral » imposé aux comptes
#                non administrateurs, retrait du bandeau d'abonnement.
#
# Auteur       : Damien SCONTRINO
#                Professeur en BTS SIO - SLAM/SISR
#                Lycée Louis Armand — Nogent-sur-Marne (94)
#
# Version      : theme_Proxmox_V28 (portable)
# Date         : Février 2025
# Dernière MàJ : Octobre 2026
#
# Compatibilité: Proxmox VE 8.x (Debian 12 bookworm)
#                Proxmox VE 9.x (Debian 13 trixie)
#                nœud seul ou cluster, quel que soit le nom des nœuds
# Dépendances  : aucune (bash, perl, coreutils : présents sur tout PVE ;
#                ssh seulement pour installer sur les autres nœuds)
# Réseau       : AUCUN téléchargement (la police Orbitron est intégrée)
# Usage        : ./install_theme_proxmox.sh [OPTIONS]   (en root)
#
# ═══════════════════════════════════════════════════════════════════
#
#   LICENCE
#
#   © 2025-2026 Damien SCONTRINO
#   BTS SIO — Lycée Louis Armand, Nogent-sur-Marne (94)
#
#   Réutilisation, modification et partage libres à des fins
#   PÉDAGOGIQUES, sous licence Creative Commons BY-NC-SA 4.0 :
#
#     - attribution : citer l'auteur d'origine ;
#     - pas d'usage commercial ;
#     - partage dans les mêmes conditions (même licence).
#
#   Texte complet de la licence :
#   https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr
#
#   Le nom de l'auteur et cette mention de licence doivent être
#   conservés dans toute copie ou version dérivée.
#
#   Ce script est fourni "en l'état", sans garantie d'aucune
#   sorte. L'auteur ne saurait être tenu responsable de tout
#   dommage direct ou indirect lié à son utilisation.
#
#   Contact : damien.scontrino@ac-creteil.fr
#             Lycée Louis Armand, Nogent-sur-Marne (94)
#
#   Police Orbitron intégrée : Copyright 2018 The Orbitron Project
#   Authors (https://github.com/theleagueof/orbitron), Reserved Font
#   Name "Orbitron", SIL Open Font License 1.1 (fichiers TTF non
#   modifiés ; licence complète : OFL-Orbitron.txt fourni à côté).
#
# ═══════════════════════════════════════════════════════════════════
#
#   CE QUE LE SCRIPT MODIFIE (et rien d'autre)
#
#   1. /usr/share/pve-manager/index.html.tpl
#        + 1 ligne <link> vers la feuille du thème (et 1 ligne
#          <script> si une option pédagogique est activée), repérées
#          par la marque « theme-proxmox-cyberpunk ».
#   2. /usr/share/pve-manager/css/theme-proxmox-cyberpunk.css  (créé)
#   3. /usr/share/pve-manager/js/theme-proxmox-cyberpunk.js    (créé,
#        seulement avec --message ou --clone-integral)
#   4. /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
#        seulement avec --sans-abonnement (1 motif neutralisé).
#   5. /etc/apt/apt.conf.d/99-theme-proxmox-cyberpunk : crochet APT
#        qui réapplique le thème après une mise à jour de Proxmox.
#   6. /opt/theme-proxmox-cyberpunk/ : copie du script + réglages.
#   Sauvegardes avant chaque modification : /root/sauvegardes-theme-proxmox/
#   Journal : /var/log/theme-proxmox-cyberpunk.log
#
#   ext6-pve.css et pvemanagerlib.js ne sont PAS modifiés (sauf
#   --nettoyer-ancien, qui retire une ancienne version du thème).
#   Aucun redémarrage de pveproxy n'est nécessaire : pveproxy relit
#   index.html.tpl à chaque chargement de page.
#
# ═══════════════════════════════════════════════════════════════════

# Les apostrophes typographiques (’) des messages sont voulues (français) :
# shellcheck disable=SC1112

set -uo pipefail
umask 022
export LC_ALL=C.UTF-8 2>/dev/null || true


###################################################################
#                    SECTION 1 : CONSTANTES                       #
###################################################################

readonly VERSION="theme_Proxmox_V28 (portable)"
readonly VERSION_COURTE="V28"
readonly MARQUE="theme-proxmox-cyberpunk"

readonly PVE_DIR="/usr/share/pve-manager"
readonly INDEX_TPL="${PVE_DIR}/index.html.tpl"
readonly CSS_DIR="${PVE_DIR}/css"
readonly JS_DIR="${PVE_DIR}/js"
readonly THEME_CSS="${CSS_DIR}/${MARQUE}.css"
readonly THEME_JS="${JS_DIR}/${MARQUE}.js"
readonly URL_CSS="/pve2/css/${MARQUE}.css"
readonly URL_JS="/pve2/js/${MARQUE}.js"
readonly ANCIEN_CSS="${CSS_DIR}/ext6-pve.css"
readonly ANCIEN_JS="${JS_DIR}/pvemanagerlib.js"
readonly TOOLKIT_JS="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

readonly INSTALL_DIR="/opt/${MARQUE}"
readonly SCRIPT_INSTALLE="${INSTALL_DIR}/install_theme_proxmox.sh"
readonly CONF="${INSTALL_DIR}/theme.conf"
readonly MESSAGE_INSTALLE="${INSTALL_DIR}/message.html"
readonly CROCHET_APT="/etc/apt/apt.conf.d/99-${MARQUE}"
readonly SAUVEGARDES="/root/sauvegardes-theme-proxmox"
readonly JOURNAL="/var/log/${MARQUE}.log"
readonly VERROU="/run/${MARQUE}.lock"

readonly BADGE_DEFAUT="%NODE%"
readonly TITRE_MESSAGE_DEFAUT="Message de l'enseignant"
readonly SSH_DELAI=5

# Signatures des anciennes versions (V27 et antérieures, « ultimate »)
readonly SIGNATURE_ANCIEN_CSS='CYBERPUNK|logoPulse|versioninfo-innerCt'
readonly SIGNATURE_ANCIEN_JS='pve-greenit-modal|popup-regles|BTSSIO-POPUP|datacenter-bg|ap-main-layout'

# Chemin réel du script lancé (pour le copier sur les autres nœuds)
SCRIPT_SOURCE="$(readlink -f "${BASH_SOURCE[0]:-$0}" 2>/dev/null || echo "$0")"
readonly SCRIPT_SOURCE
SCRIPT_NOM="$(basename "$0")"
readonly SCRIPT_NOM


###################################################################
#                SECTION 2 : VARIABLES GLOBALES                   #
###################################################################

ACTION=""              # installer | desinstaller | etat | reappliquer | nettoyer | menu
MODE_AUTO=0            # 1 = aucune question
SIMULATION=0           # 1 = rien n'est modifié
SILENCE=0              # 1 = mode crochet APT (une ligne au plus)
FORCER=0               # 1 = accepte une version de PVE non testée
CLUSTER=0              # 1 = traiter aussi les autres nœuds du cluster
NETTOYER_ANCIEN=0      # 1 = retirer l'ancienne version du thème (V27)

OPT_BADGE=""           # texte du badge (%NODE% = nom du nœud)
OPT_BADGE_FIXE=0
OPT_SANS_ABO=0         # 1 = neutraliser le bandeau « No valid subscription »
OPT_SANS_ABO_FIXE=0
OPT_MESSAGE=""         # fichier du message d'accueil (vide = aucun)
OPT_MESSAGE_FIXE=0
OPT_SANS_MESSAGE=0
OPT_TITRE_MESSAGE=""
OPT_CLONE=0            # 1 = clone intégral imposé aux non-administrateurs
OPT_CLONE_FIXE=0

# Réglages lus dans ${CONF} (installation précédente)
CONF_BADGE=""; CONF_SANS_ABO=0; CONF_ABO_PAR_SCRIPT=0; CONF_MESSAGE=0
CONF_TITRE_MESSAGE=""; CONF_CLONE=0; CONF_VERSION=""; CONF_DATE=""; CONF_FORCER=0
CONF_PRESENTE=0

NOEUD=""               # nom du nœud Proxmox (/etc/pve/local)
PVE_VERSION=""         # ex : 8.4.17
PVE_MAJEUR=""          # ex : 8
DEBIAN_VERSION=""      # ex : 12.13
DEBIAN_NOM=""          # ex : bookworm
EST_CLUSTER=0
declare -a NOEUDS_DISTANTS=()
declare -A IP_NOEUD=()
declare -A ENLIGNE_NOEUD=()
declare -A SSH_OPTS_NOEUD=()

NB_ERREURS=0
ANCIEN_CSS_PRESENT=0
ANCIEN_JS_PRESENT=0
TMP_LOCAL=""
HORODATAGE="$(date +%Y%m%d-%H%M%S)"
DOSSIER_SAUVEGARDE=""  # créé à la première modification
declare -a BILAN=()


###################################################################
#              SECTION 3 : AFFICHAGE ET JOURNAL                   #
###################################################################

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RAZ=$'\e[0m'; C_GRAS=$'\e[1m'; C_ROUGE=$'\e[31m'; C_VERT=$'\e[32m'
    C_JAUNE=$'\e[33m'; C_CYAN=$'\e[36m'; C_GRIS=$'\e[90m'
else
    C_RAZ=""; C_GRAS=""; C_ROUGE=""; C_VERT=""; C_JAUNE=""; C_CYAN=""; C_GRIS=""
fi

ok()        { (( SILENCE )) || printf '   %s✔%s %s\n' "$C_VERT" "$C_RAZ" "$*"; }
info()      { (( SILENCE )) || printf '   %s➜%s %s\n' "$C_CYAN" "$C_RAZ" "$*"; }
detail()    { (( SILENCE )) || printf '     %s%s%s\n' "$C_GRIS" "$*" "$C_RAZ"; }
attention() { (( SILENCE )) || printf '   %s⚠ %s%s\n' "$C_JAUNE" "$*" "$C_RAZ"; }
erreur()    { printf '   %s✘ ERREUR : %s%s\n' "$C_ROUGE" "$*" "$C_RAZ" >&2; NB_ERREURS=$((NB_ERREURS + 1)); journal "ERREUR : $*"; }
simule()    { (( SILENCE )) || printf '   %s[simulation]%s %s\n' "$C_JAUNE" "$C_RAZ" "$*"; }
etape()     { (( SILENCE )) || printf '\n%s── %s ──%s\n' "$C_GRAS$C_CYAN" "$*" "$C_RAZ"; }

fatal() {
    printf '\n   %s✘ ERREUR BLOQUANTE : %s%s\n' "$C_ROUGE" "$*" "$C_RAZ" >&2
    printf "   Rien n'a été modifié par cette étape. Le script s'arrête.\n\n" >&2
    journal "ARRET : $*"
    exit 1
}

bandeau() {
    (( SILENCE )) && return 0
    printf '%s═══════════════════════════════════════════════════════════════%s\n' "$C_CYAN" "$C_RAZ"
    printf '%s  THÈME PROXMOX CYBERPUNK — %s%s\n' "$C_GRAS" "$VERSION" "$C_RAZ"
    printf '  Damien SCONTRINO — BTS SIO — CC BY-NC-SA 4.0\n'
    printf '%s═══════════════════════════════════════════════════════════════%s\n' "$C_CYAN" "$C_RAZ"
}

journal() {
    (( SIMULATION )) && return 0
    [[ "$(id -u)" -eq 0 ]] || return 0
    { printf '[%s] %s : %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${NOEUD:-?}" "$*" >> "$JOURNAL"; } 2>/dev/null || true
}

bilan() { BILAN+=("$*"); }

question_oui_non() {   # $1 = question, $2 = défaut (o/n) → code retour 0 = oui
    local rep defaut="$2" invite
    if [[ "$defaut" == "o" ]]; then invite="(O/n)"; else invite="(o/N)"; fi
    read -rp "   $1 $invite : " rep || rep=""
    rep="${rep:-$defaut}"
    [[ "$rep" =~ ^[oOyY] ]]
}


###################################################################
#                SECTION 4 : AIDE ET ARGUMENTS                    #
###################################################################

usage() {
    cat << EOF
Usage : ${SCRIPT_NOM} [ACTION] [OPTIONS]        (à lancer en root)

Thème cyberpunk bleu néon pour l'interface web de Proxmox VE 8.x / 9.x.
Sans argument : menu interactif (installer, désinstaller, état, simulation).

Actions :
  --installer, --auto     Installe ou met à jour le thème SANS question
  --desinstaller          Retire le thème et restaure les fichiers d'origine
                          (alias : --restore, --uninstall)
  --etat                  Affiche ce qui est installé (ne modifie rien)
  --nettoyer-ancien       Retire une ANCIENNE version du thème (V27 et avant,
                          ajoutée dans ext6-pve.css), contrôle md5 du paquet
  --reappliquer           Utilisé par le crochet APT après une mise à jour
  -h, --help              Cette aide
  -v, --version           Version du script

Options d'installation :
  --badge "TEXTE"         Texte du badge de la barre du haut
                          (%NODE% = nom du nœud ; défaut : "${BADGE_DEFAUT}")
  --sans-abonnement       Neutralise la fenêtre « No valid subscription »
                          (alias : --no-sub)
  --avec-abonnement       Remet la fenêtre d'abonnement (si ce script l'avait retirée)
  --message FICHIER       Message d'accueil affiché après la connexion (une fois
                          par session du navigateur). FICHIER .html ou texte brut.
  --titre-message "TXT"   Titre de la fenêtre du message (défaut : "${TITRE_MESSAGE_DEFAUT}")
  --sans-message          Supprime le message d'accueil
  --clone-integral        Comptes NON administrateurs : seul « Clone intégral »
                          est proposé quand ils clonent un modèle
  --sans-clone-integral   Désactive l'option précédente

Options générales :
  --cluster               Agit aussi sur les AUTRES nœuds du cluster (SSH root)
  --simulation            Vérifie tout et montre ce qui serait fait, sans rien
                          modifier (alias : --dry-run)
  --forcer                Accepte une version de Proxmox autre que 8.x / 9.x

Exemples :
  ${SCRIPT_NOM}                                          # menu interactif
  ${SCRIPT_NOM} --simulation --auto                      # essai à blanc
  ${SCRIPT_NOM} --auto --badge "%NODE% - Lycée Exemple"  # installation directe
  ${SCRIPT_NOM} --auto --sans-abonnement --cluster       # + tous les nœuds
  ${SCRIPT_NOM} --auto --message regles.html --clone-integral
  ${SCRIPT_NOM} --desinstaller                           # retour à l'origine

Après installation : rafraîchir la page du navigateur (Ctrl+F5).
EOF
}

analyser_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)            usage; exit 0 ;;
            -v|--version)         echo "${SCRIPT_NOM} ${VERSION}"; exit 0 ;;
            --installer|--install)
                                  ACTION="installer"; MODE_AUTO=1; shift ;;
            --auto)               MODE_AUTO=1; [[ -z "$ACTION" ]] && ACTION="installer"; shift ;;
            --desinstaller|--désinstaller|--restore|--uninstall)
                                  ACTION="desinstaller"; shift ;;
            --etat|--état|--status) ACTION="etat"; shift ;;
            --reappliquer|--réappliquer)
                                  ACTION="reappliquer"; MODE_AUTO=1; SILENCE=1; shift ;;
            --nettoyer-ancien)    NETTOYER_ANCIEN=1; shift ;;
            --badge)              [[ $# -ge 2 ]] || fatal "--badge attend un texte"
                                  OPT_BADGE="$2"; OPT_BADGE_FIXE=1; shift 2 ;;
            --sans-abonnement|--no-sub)
                                  OPT_SANS_ABO=1; OPT_SANS_ABO_FIXE=1; shift ;;
            --avec-abonnement)    OPT_SANS_ABO=0; OPT_SANS_ABO_FIXE=1; shift ;;
            --message)            [[ $# -ge 2 ]] || fatal "--message attend un fichier"
                                  OPT_MESSAGE="$2"; OPT_MESSAGE_FIXE=1; shift 2 ;;
            --titre-message)      [[ $# -ge 2 ]] || fatal "--titre-message attend un texte"
                                  OPT_TITRE_MESSAGE="$2"; shift 2 ;;
            --sans-message)       OPT_SANS_MESSAGE=1; OPT_MESSAGE=""; OPT_MESSAGE_FIXE=1; shift ;;
            --clone-integral)     OPT_CLONE=1; OPT_CLONE_FIXE=1; shift ;;
            --sans-clone-integral) OPT_CLONE=0; OPT_CLONE_FIXE=1; shift ;;
            --cluster)            CLUSTER=1; shift ;;
            --sans-cluster)       CLUSTER=0; shift ;;
            --simulation|--dry-run) SIMULATION=1; shift ;;
            --forcer|--force)     FORCER=1; shift ;;
            *) fatal "option inconnue : $1 (voir --help)" ;;
        esac
    done
    # --nettoyer-ancien seul = action de nettoyage ; avec --auto = pendant l'installation
    if [[ -z "$ACTION" && "$NETTOYER_ANCIEN" -eq 1 ]]; then ACTION="nettoyer"; MODE_AUTO=1; fi
    if [[ -n "$OPT_MESSAGE" && ! -r "$OPT_MESSAGE" ]]; then
        fatal "fichier de message illisible : ${OPT_MESSAGE}"
    fi
    return 0
}


###################################################################
#           SECTION 5 : VÉRIFICATIONS ET DÉTECTION                #
###################################################################

verifier_root() {
    [[ "$(id -u)" -eq 0 ]] || fatal "ce script doit être lancé en root (sudo -i, puis relancer)."
}

detecter_proxmox() {
    command -v pveversion >/dev/null 2>&1 || fatal "pveversion introuvable : ce serveur n'est pas un Proxmox VE."
    [[ -d "$PVE_DIR" ]] || fatal "${PVE_DIR} absent : le paquet pve-manager n'est pas installé."
    [[ -f "$INDEX_TPL" ]] || fatal "${INDEX_TPL} absent : installation de Proxmox incomplète."

    local brut
    brut="$(pveversion 2>/dev/null | head -1)"
    PVE_VERSION="${brut#pve-manager/}"
    PVE_VERSION="${PVE_VERSION%%/*}"
    PVE_MAJEUR="${PVE_VERSION%%.*}"
    [[ "$PVE_MAJEUR" =~ ^[0-9]+$ ]] || fatal "version de Proxmox illisible (« ${brut} »)."

    DEBIAN_VERSION="$(cat /etc/debian_version 2>/dev/null || echo '?')"
    DEBIAN_NOM="$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release 2>/dev/null | tr -d '"')"
    DEBIAN_NOM="${DEBIAN_NOM:-?}"

    # Nom du nœud tel que Proxmox le connaît (/etc/pve/local -> nodes/<nom>)
    if [[ -L /etc/pve/local ]]; then
        NOEUD="$(basename "$(readlink /etc/pve/local)")"
    else
        NOEUD="$(hostname -s 2>/dev/null || hostname)"
    fi
    if [[ -f /etc/pve/corosync.conf ]]; then EST_CLUSTER=1; fi
    return 0
}

verifier_version() {   # $1 = 1 si la version doit être bloquante
    local bloquant="${1:-1}"
    case "$PVE_MAJEUR" in
        8|9) ok "Proxmox VE ${PVE_VERSION} (Debian ${DEBIAN_VERSION} ${DEBIAN_NOM}) : version prise en charge" ;;
        *)
            if (( FORCER )) || [[ "$bloquant" -eq 0 ]]; then
                attention "Proxmox VE ${PVE_VERSION} : version NON testée (prévu pour 8.x et 9.x)."
            else
                fatal "Proxmox VE ${PVE_VERSION} n'est pas pris en charge (8.x ou 9.x attendu). Option --forcer pour essayer quand même."
            fi ;;
    esac
    if [[ "$PVE_MAJEUR" == "8" && "${DEBIAN_VERSION%%.*}" != "12" ]] || \
       [[ "$PVE_MAJEUR" == "9" && "${DEBIAN_VERSION%%.*}" != "13" ]]; then
        attention "Couple inhabituel PVE ${PVE_MAJEUR} / Debian ${DEBIAN_VERSION} (mise à niveau en cours ?)."
    fi
}

verifier_fichiers() {   # $1 = 1 si l'option « sans abonnement » est demandée
    local besoin_toolkit="${1:-0}" n
    n="$(grep -c '</head>' "$INDEX_TPL" 2>/dev/null || true)"
    [[ "$n" == "1" ]] || fatal "${INDEX_TPL} : balise </head> trouvée ${n:-0} fois (1 attendue). Fichier inhabituel : rien n'est modifié."
    [[ -d "$CSS_DIR" ]] || fatal "dossier ${CSS_DIR} absent."
    [[ -d "$JS_DIR" ]]  || fatal "dossier ${JS_DIR} absent."
    if [[ "$besoin_toolkit" -eq 1 && ! -f "$TOOLKIT_JS" ]]; then
        fatal "${TOOLKIT_JS} absent (paquet proxmox-widget-toolkit)."
    fi
    command -v perl >/dev/null 2>&1 || fatal "perl absent (il est pourtant fourni avec Proxmox)."
    perl -MDigest::MD5 -MJSON::PP -e 1 2>/dev/null || fatal "modules perl Digest::MD5 / JSON::PP absents."
    ok "Fichiers de l'interface présents (index.html.tpl, css/, js/)"
}

# md5 d'origine d'un fichier, d'après la liste du paquet Debian (dpkg)
md5_paquet() {
    local rel="${1#/}"
    grep -h -F -- "  ${rel}" /var/lib/dpkg/info/*.md5sums 2>/dev/null \
        | awk -v r="$rel" '$2 == r { print $1; exit }'
}

# "origine" | "modifie" | "inconnu"
etat_paquet() {
    local f="$1" attendu reel
    attendu="$(md5_paquet "$f")"
    [[ -n "$attendu" && -f "$f" ]] || { echo "inconnu"; return; }
    reel="$(md5sum < "$f" | cut -d' ' -f1)"
    if [[ "$reel" == "$attendu" ]]; then echo "origine"; else echo "modifie"; fi
}

# md5 d'un flux lu sur l'entrée standard
md5_flux() { md5sum | cut -d' ' -f1; }

# Le modèle index.html.tpl privé de NOS lignes est-il celui du paquet ?
template_sans_nos_lignes_origine() {
    local attendu
    attendu="$(md5_paquet "$INDEX_TPL")"
    [[ -n "$attendu" ]] || return 2
    [[ "$(grep -vF "$MARQUE" "$INDEX_TPL" | md5_flux)" == "$attendu" ]]
}

# Longueur (octets) du plus court début de fichier dont le md5 est celui du
# paquet : sert à retirer proprement ce qu'une ancienne version a AJOUTÉ à la
# fin d'un fichier, sans réseau et avec preuve (md5 identique au paquet).
longueur_origine() {
    perl -MDigest::MD5 -e '
        my ($f, $cible) = @ARGV;
        open(my $fh, "<:raw", $f) or exit 2;
        local $/; my $c = <$fh>; close $fh;
        my $ctx = Digest::MD5->new; my $pos = 0;
        for my $ligne (split /(?<=\n)/, $c) {
            my $corps = $ligne; my $nl = ($corps =~ s/\n\z//);
            if (length $corps) { $ctx->add($corps); $pos += length $corps;
                if ($ctx->clone->hexdigest eq $cible) { print $pos; exit 0 } }
            if ($nl) { $ctx->add("\n"); $pos++;
                if ($ctx->clone->hexdigest eq $cible) { print $pos; exit 0 } }
        }
        exit 1;' "$1" "$2"
}

# État du bandeau d'abonnement dans proxmoxlib.js : neutralise | present | introuvable | absent
etat_abonnement() {
    [[ -f "$TOOLKIT_JS" ]] || { echo "absent"; return; }
    perl -0777 -ne '
        if (/void\(\{ \/\/Ext\.Msg\.show\(\{\s+title: gettext\(.No valid subscription.\)/) { print "neutralise"; exit }
        if (/Ext\.Msg\.show\(\{\s+title: gettext\(.No valid subscription.\)/) { print "present"; exit }
        print "introuvable";' "$TOOLKIT_JS"
}

lire_conf() {
    [[ -f "$CONF" ]] || return 0
    # Le fichier doit appartenir à root et n'être modifiable que par lui
    if [[ "$(stat -c '%u' "$CONF")" != "0" ]] || [[ -n "$(find "$CONF" -perm /022 2>/dev/null)" ]]; then
        attention "${CONF} : propriétaire ou droits anormaux, réglages ignorés."
        return 0
    fi
    # shellcheck source=/dev/null
    . "$CONF"
    CONF_PRESENTE=1
}

ecrire_conf() {
    (( SIMULATION )) && { simule "écrirait les réglages dans ${CONF}"; return 0; }
    mkdir -p "$INSTALL_DIR" && chmod 700 "$INSTALL_DIR"
    local t="${TMP_LOCAL}/theme.conf"
    {
        echo "# Réglages du thème Proxmox cyberpunk — généré par install_theme_proxmox.sh"
        echo "# Ne pas modifier à la main : relancer le script avec les options voulues."
        printf 'CONF_VERSION=%q\n' "$VERSION_COURTE"
        printf 'CONF_BADGE=%q\n' "$OPT_BADGE"
        printf 'CONF_SANS_ABO=%q\n' "$OPT_SANS_ABO"
        printf 'CONF_ABO_PAR_SCRIPT=%q\n' "$CONF_ABO_PAR_SCRIPT"
        printf 'CONF_MESSAGE=%q\n' "$([[ -n "$OPT_MESSAGE" ]] && echo 1 || echo 0)"
        printf 'CONF_TITRE_MESSAGE=%q\n' "$OPT_TITRE_MESSAGE"
        printf 'CONF_CLONE=%q\n' "$OPT_CLONE"
        printf 'CONF_FORCER=%q\n' "$FORCER"
    } > "$t"
    # Réécrit seulement si un réglage change (le crochet APT passe souvent)
    if [[ -f "$CONF" ]] && cmp -s "$t" <(grep -v '^CONF_DATE=' "$CONF"); then return 0; fi
    printf 'CONF_DATE=%q\n' "$(date '+%Y-%m-%d %H:%M')" >> "$t"
    install -m 0600 -o root -g root "$t" "$CONF" || erreur "écriture de ${CONF} impossible"
}

# Options effectives = ligne de commande, sinon installation précédente, sinon défaut
fusionner_options() {
    if (( ! OPT_BADGE_FIXE )); then OPT_BADGE="${CONF_BADGE:-$BADGE_DEFAUT}"; fi
    [[ -n "$OPT_BADGE" ]] || OPT_BADGE="$BADGE_DEFAUT"
    if (( ! OPT_SANS_ABO_FIXE )); then OPT_SANS_ABO="${CONF_SANS_ABO:-0}"; fi
    if (( ! OPT_CLONE_FIXE )); then OPT_CLONE="${CONF_CLONE:-0}"; fi
    if (( ! OPT_MESSAGE_FIXE )) && [[ "${CONF_MESSAGE:-0}" == "1" && -f "$MESSAGE_INSTALLE" ]]; then
        OPT_MESSAGE="$MESSAGE_INSTALLE"
    fi
    [[ -n "$OPT_TITRE_MESSAGE" ]] || OPT_TITRE_MESSAGE="${CONF_TITRE_MESSAGE:-$TITRE_MESSAGE_DEFAUT}"
    (( CONF_FORCER )) && FORCER=1
    return 0
}

detecter_anciennes_versions() {   # affiche ce qui reste des anciennes versions
    ANCIEN_CSS_PRESENT=0; ANCIEN_JS_PRESENT=0
    if [[ -f "$ANCIEN_CSS" ]] && grep -qE "$SIGNATURE_ANCIEN_CSS" "$ANCIEN_CSS"; then
        ANCIEN_CSS_PRESENT=1
        attention "Ancienne version du thème trouvée dans ext6-pve.css (V27 ou antérieure)."
        detail "Elle reste active par-dessous ; --nettoyer-ancien la retire proprement (contrôle md5)."
    fi
    if [[ -f "$ANCIEN_JS" ]] && grep -qE "$SIGNATURE_ANCIEN_JS" "$ANCIEN_JS"; then
        ANCIEN_JS_PRESENT=1
        attention "Ancien message (pop-up) ajouté dans pvemanagerlib.js détecté."
        detail "--nettoyer-ancien peut le retirer (seulement si le reste du fichier est celui du paquet)."
    fi
    local c
    for c in /etc/apt/apt.conf.d/99-pve-neon-theme /etc/apt/apt.conf.d/99-pve-btssio-popup; do
        if [[ -f "$c" ]]; then
            attention "Crochet APT d'une ancienne installation présent : ${c}"
            detail "Il peut réinjecter l'ancienne version après chaque mise à jour : à retirer si vous passez à la V28."
        fi
    done
    return 0
}


###################################################################
#           SECTION 6 : CLUSTER (autres nœuds, via SSH)           #
###################################################################

lister_noeuds_distants() {
    NOEUDS_DISTANTS=()
    local json nom ip enligne local_
    json="$(pvesh get /cluster/status --output-format json 2>/dev/null)" || {
        attention "pvesh get /cluster/status a échoué : impossible de lister les nœuds."; return 0; }
    while read -r nom ip enligne local_; do
        [[ -n "$nom" && "$local_" != "1" ]] || continue
        NOEUDS_DISTANTS+=("$nom")
        IP_NOEUD["$nom"]="$ip"
        ENLIGNE_NOEUD["$nom"]="$enligne"
    done < <(printf '%s' "$json" | perl -MJSON::PP -e '
        local $/; my $d = eval { decode_json(<STDIN>) } || [];
        for my $e (@$d) {
            next unless ($e->{type} // "") eq "node";
            printf "%s %s %d %d\n", $e->{name}, ($e->{ip} // "-"), ($e->{online} ? 1 : 0), ($e->{local} ? 1 : 0);
        }')
    return 0
}

# Trouve une façon de joindre le nœud en SSH (clé root du cluster), sans question
preparer_ssh() {
    local nom="$1" ip="${IP_NOEUD[$1]:-}" essai
    local -a base=(-o BatchMode=yes -o ConnectTimeout="$SSH_DELAI")
    local -a essais=()
    if [[ -f "/etc/pve/nodes/${nom}/ssh_known_hosts" && -n "$ip" && "$ip" != "-" ]]; then
        essais+=("-o UserKnownHostsFile=/etc/pve/nodes/${nom}/ssh_known_hosts -o GlobalKnownHostsFile=none -o HostKeyAlias=${nom} root@${ip}")
    fi
    essais+=("root@${nom}")
    [[ -n "$ip" && "$ip" != "-" ]] && essais+=("-o HostKeyAlias=${nom} root@${ip}" "root@${ip}")
    for essai in "${essais[@]}"; do
        # shellcheck disable=SC2086
        if ssh "${base[@]}" $essai true </dev/null >/dev/null 2>&1; then
            SSH_OPTS_NOEUD["$nom"]="$essai"
            return 0
        fi
    done
    return 1
}

ssh_noeud() {   # $1 = nœud, reste = commande distante
    local nom="$1"; shift
    # shellcheck disable=SC2086
    ssh -o BatchMode=yes -o ConnectTimeout="$SSH_DELAI" ${SSH_OPTS_NOEUD[$nom]} "$@"
}

scp_noeud() {   # $1 = nœud, $2 = dossier distant, reste = fichiers locaux
    local nom="$1" dest="$2"; shift 2
    local opts="${SSH_OPTS_NOEUD[$nom]}" hote
    hote="${opts##* }"; opts="${opts% *}"; [[ "$opts" == "$hote" ]] && opts=""
    # shellcheck disable=SC2086
    scp -q -o BatchMode=yes -o ConnectTimeout="$SSH_DELAI" $opts "$@" "${hote}:${dest}/"
}

# Exécute ce même script sur chaque autre nœud du cluster
traiter_noeuds_distants() {   # $@ = arguments à passer au script distant
    local nom tmp arguments="" a reussis=0
    local -a echecs=()
    lister_noeuds_distants
    if [[ ${#NOEUDS_DISTANTS[@]} -eq 0 ]]; then
        info "Aucun autre nœud dans ce cluster."
        return 0
    fi
    for a in "$@"; do arguments+=" $(printf '%q' "$a")"; done
    etape "Autres nœuds du cluster : ${NOEUDS_DISTANTS[*]}"
    for nom in "${NOEUDS_DISTANTS[@]}"; do
        printf '\n   %s■ %s%s (%s)\n' "$C_GRAS" "$nom" "$C_RAZ" "${IP_NOEUD[$nom]:-?}"
        if [[ "${ENLIGNE_NOEUD[$nom]:-0}" != "1" ]]; then
            erreur "${nom} est hors ligne pour le cluster : ignoré."; echecs+=("$nom"); continue
        fi
        if ! preparer_ssh "$nom"; then
            erreur "${nom} : connexion SSH root impossible sans mot de passe."; echecs+=("$nom"); continue
        fi
        ok "SSH vers ${nom} : OK (${SSH_OPTS_NOEUD[$nom]##* })"
        if (( SIMULATION )); then
            local distant
            distant="$(ssh_noeud "$nom" "pveversion 2>/dev/null | head -1; grep -c '</head>' ${INDEX_TPL} 2>/dev/null; grep -c ${MARQUE} ${INDEX_TPL} 2>/dev/null" </dev/null 2>/dev/null | tr '\n' ' ')"
            simule "${nom} : ${distant:-?}(version / </head> / lignes du thème) — copierait le script et lancerait :${arguments}"
            reussis=$((reussis + 1)); continue
        fi
        tmp="$(ssh_noeud "$nom" "mktemp -d /tmp/${MARQUE}.XXXXXX" </dev/null 2>/dev/null)"
        if [[ -z "$tmp" ]]; then erreur "${nom} : création d'un dossier temporaire impossible."; echecs+=("$nom"); continue; fi
        local -a fichiers=("$SCRIPT_SOURCE")
        if [[ -n "$OPT_MESSAGE" && -f "$OPT_MESSAGE" ]]; then
            [[ "$OPT_MESSAGE" -ef "${TMP_LOCAL}/message.html" ]] || cp -f "$OPT_MESSAGE" "${TMP_LOCAL}/message.html"
            fichiers+=("${TMP_LOCAL}/message.html")
        fi
        if ! scp_noeud "$nom" "$tmp" "${fichiers[@]}" </dev/null; then
            erreur "${nom} : copie du script impossible."; echecs+=("$nom"); continue
        fi
        local cmd
        cmd="bash ${tmp}/$(basename "$SCRIPT_SOURCE")${arguments}"
        if [[ -n "$OPT_MESSAGE" && -f "$OPT_MESSAGE" && " $* " == *" --installer "* ]]; then
            cmd+=" --message ${tmp}/message.html"
        fi
        cmd+="; rc=\$?; rm -rf ${tmp}; exit \$rc"
        if NO_COLOR=1 ssh_noeud "$nom" "$cmd" </dev/null 2>&1 | sed 's/^/   │ /'; then
            ok "${nom} : terminé"; reussis=$((reussis + 1))
        else
            erreur "${nom} : le script distant a signalé une erreur."; echecs+=("$nom")
        fi
    done
    bilan "Autres nœuds : ${reussis}/${#NOEUDS_DISTANTS[@]} réussis${echecs[*]:+ — échecs : ${echecs[*]}}"
}


###################################################################
#        SECTION 7 : SAUVEGARDE ET ÉCRITURE DES FICHIERS          #
###################################################################

sauvegarder() {   # copie les fichiers AVANT modification
    (( SIMULATION )) && return 0
    local f
    if [[ -z "$DOSSIER_SAUVEGARDE" ]]; then
        DOSSIER_SAUVEGARDE="${SAUVEGARDES}/${HORODATAGE}-${ACTION}"
        mkdir -p "$DOSSIER_SAUVEGARDE" && chmod 700 "$SAUVEGARDES" "$DOSSIER_SAUVEGARDE"
        {
            echo "Nœud : ${NOEUD} — Proxmox VE ${PVE_VERSION} — Debian ${DEBIAN_VERSION}"
            echo "Action : ${ACTION} — $(date '+%Y-%m-%d %H:%M:%S') — ${VERSION}"
        } > "${DOSSIER_SAUVEGARDE}/LISEZMOI.txt"
    fi
    for f in "$@"; do
        [[ -f "$f" ]] || continue
        [[ -f "${DOSSIER_SAUVEGARDE}/$(basename "$f")" ]] && continue
        cp -p "$f" "${DOSSIER_SAUVEGARDE}/" || { erreur "sauvegarde impossible de ${f}"; return 1; }
        (cd "$DOSSIER_SAUVEGARDE" && sha256sum "$(basename "$f")" >> SHA256SUMS)
        printf '%s\n' "$f" >> "${DOSSIER_SAUVEGARDE}/chemins.txt"
    done
    # On garde les 15 sauvegardes les plus récentes
    find "$SAUVEGARDES" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | sort -r | tail -n +16 | while read -r vieux; do rm -rf "${SAUVEGARDES:?}/${vieux}"; done
    return 0
}

# Remplace un fichier de façon atomique (fichier temporaire dans le même dossier + mv)
remplacer_fichier() {   # $1 = contenu (fichier temporaire), $2 = destination
    local src="$1" dest="$2" t
    t="$(mktemp "$(dirname "$dest")/.${MARQUE}.XXXXXX")" || return 1
    if cat "$src" > "$t" && chmod 0644 "$t" && chown root:root "$t" && mv -f "$t" "$dest"; then
        return 0
    fi
    rm -f "$t"; return 1
}


###################################################################
#              SECTION 8 : GÉNÉRATION DU CSS DU THÈME             #
#                                                                 #
#  LÉGENDE DES ICÔNES :                                           #
#    VM/LXC running    → noir + halo cyan                         #
#    VM/LXC stopped    → rouge néon #cc2244                       #
#    Templates         → violet #9966aa                           #
#    Nœud (fa-server)  → cyan électrique #00ffff                  #
#    Datacenter        → blanc + halo blanc                       #
#    Ceph (PNG)        → blanc (filtre invert)                    #
#    Bulk actions      → vert / rouge / orange                    #
###################################################################

echapper_css() {   # texte → chaîne CSS sûre entre guillemets doubles
    local s="$1"
    s="${s//$'\n'/ }"; s="${s//$'\r'/}"; s="${s//$'\t'/ }"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

generer_css() {   # $1 = texte du badge (déjà résolu)
    local badge corps
    badge="$(echapper_css "$1")"
    corps="$(css_corps)"
    corps="${corps//@@BADGE@@/"$badge"}"
    corps="${corps//@@ORBITRON700@@/"$(police_orbitron_700)"}"
    corps="${corps//@@ORBITRON900@@/"$(police_orbitron_900)"}"
    printf '@charset "UTF-8";\n'
    printf '/* ═══════════════════════════════════════════════════════════════\n'
    printf ' * THÈME PROXMOX CYBERPUNK BLEU NÉON — %s\n' "$VERSION"
    printf ' * Damien SCONTRINO — BTS SIO — CC BY-NC-SA 4.0\n'
    printf ' * Fichier généré par install_theme_proxmox.sh : ne pas le modifier,\n'
    printf ' * relancer le script. Retrait : install_theme_proxmox.sh --desinstaller\n'
    printf ' * ═══════════════════════════════════════════════════════════════ */\n'
    printf '%s\n' "$corps"
}

css_corps() {
cat << 'FIN_CSS'

/* ─── 00. POLICE ORBITRON ─────────────────────────────────────
 * Integree dans ce fichier (data URI base64) : aucun telechargement.
 * Orbitron (c) 2018 The Orbitron Project Authors, Reserved Font
 * Name "Orbitron", SIL Open Font License 1.1 (TTF non modifies).
 * Repli : Consolas / monospace.
 * ──────────────────────────────────────────────────────────── */

@font-face {
    font-family: 'Orbitron';
    font-weight: 700;
    font-display: swap;
    src: url(data:font/ttf;base64,@@ORBITRON700@@) format('truetype');
}

@font-face {
    font-family: 'Orbitron';
    font-weight: 900;
    font-display: swap;
    src: url(data:font/ttf;base64,@@ORBITRON900@@) format('truetype');
}


/* ─── 01. FOND PRINCIPAL + PARTICULES ─────────────────────────
 * Degrade sombre fixe avec 5 points lumineux animes en overlay
 * via mix-blend-mode:screen pour un effet "ciel etoile" subtil.
 * ──────────────────────────────────────────────────────────── */

body {
    background: linear-gradient(135deg, #0a0e1a 0%, #0d1424 50%, #0a1220 100%) !important;
    background-attachment: fixed !important;
}

body::before {
    content: "";
    position: fixed;
    top: 0; left: 0; width: 100%; height: 100%;
    background-image:
        radial-gradient(2px 2px at 15% 25%, rgba(0,212,255,0.6), transparent 40%),
        radial-gradient(3px 3px at 85% 75%, rgba(0,180,255,0.5), transparent 40%),
        radial-gradient(2px 2px at 50% 50%, rgba(100,200,255,0.5), transparent 40%),
        radial-gradient(1px 1px at 30% 60%, rgba(0,230,255,0.7), transparent 30%),
        radial-gradient(2px 2px at 70% 30%, rgba(0,200,255,0.6), transparent 35%);
    animation: particlesFloat 25s linear infinite !important;
    pointer-events: none;
    z-index: 1;
    mix-blend-mode: screen;
}

@keyframes particlesFloat {
    0%   { transform: translateY(0) translateX(0); opacity: 0.7; }
    50%  { transform: translateY(-50px) translateX(30px); opacity: 1; }
    100% { transform: translateY(-100px) translateX(-20px); opacity: 0.7; }
}

body > * { position: relative; z-index: 2; }


/* ─── 02. PANNEAUX, GRILLES, FONDS SOMBRES ──────────────────── */

.x-panel-body, .x-panel-body-default,
.x-grid-item-container, .x-panel.x-grid,
.x-tree-view, .x-grid-body, .x-grid-view,
.x-fit-item, .x-panel-bodyWrap,
.x-docked-noborder-top, .x-docked-noborder-bottom,
.x-panel-default, .x-window-default {
    background: rgba(15,25,45,0.95) !important;
    background-color: rgba(15,25,45,0.95) !important;
}

.x-grid-item {
    background: transparent !important;
    border-bottom: 1px solid rgba(0,180,255,0.1) !important;
}
.x-grid-item:nth-child(even) {
    background: rgba(20,30,50,0.7) !important;
}

.x-grid-empty, div.x-grid-empty {
    background: rgba(15,25,45,0.95) !important;
    background-color: rgba(15,25,45,0.95) !important;
    color: #a0b8d0 !important;
}

.x-toolbar-default, .x-toolbar-footer {
    background: rgba(15,25,45,0.9) !important;
}
.x-tab-bar, .x-tab-bar-default {
    background: rgba(15,25,45,0.95) !important;
}

.install-mask, p.install-mask,
.x-window-body-install-mask, .x-panel-body-install-mask {
    background: rgba(15,25,45,0.95) !important;
    background-color: rgba(15,25,45,0.95) !important;
    color: #e8f4ff !important;
}

.x-mask-msg, .x-mask-msg-text, div.x-mask-msg-text,
.x-mask-msg-inner, .pve-static-mask, .x-mask.x-border-box {
    background: rgba(15,25,45,0.95) !important;
    background-color: rgba(15,25,45,0.95) !important;
    color: #e8f4ff !important;
    border: 1px solid rgba(0,212,255,0.3) !important;
}


/* ─── 03. TEXTE GLOBAL : BLANC NET ──────────────────────────── */

.x-grid-item .x-grid-cell,
.x-grid-item .x-grid-cell-inner,
.x-grid-cell, .x-grid-cell-inner {
    color: #e8f4ff !important;
    text-shadow: none !important;
    font-weight: 500 !important;
}

.x-tree-node-text, span.x-tree-node-text {
    color: #ffffff !important;
    text-shadow: none !important;
    font-weight: 400 !important;
}

.x-panel-body h3, .x-panel-body-default h3,
.x-table-layout-cell h3, .x-component h3 {
    color: #e8f4ff !important;
    text-shadow: none !important;
}

.x-panel-body .left-aligned, .x-panel-body-default .left-aligned,
.x-panel-body p, .x-panel-body-default p, .pmx-md p,
.x-autocontainer-innerct p, .x-component.x-component-default,
div[style*="white-space:pre"], .x-autocontainer-innerct > div,
.x-panel-body .x-component, .x-panel-body div, .x-panel-body-default div,
.x-table-layout-ct div, .x-scroller div, .x-docked-noborder-right div,
.x-panel-body span, .x-panel-body-default span, .x-table-layout-cell span,
.centered-flex-column, .x-component.centered-flex-column {
    color: #e8f4ff !important;
}

.x-form-display-field, .x-form-display-field-default {
    color: #e8f4ff !important;
}


/* ─── 04. EXCEPTION TAGS PROXMOX ──────────────────────────────
 * proxmox-tag-dark  = fond clair → texte NOIR
 * proxmox-tag-light = fond sombre → texte BLANC
 * ──────────────────────────────────────────────────────────── */

span.proxmox-tag-dark,
span.proxmox-tag-dark[style],
.x-grid-cell span.proxmox-tag-dark[style],
.x-grid-cell-inner span.proxmox-tag-dark[style],
div span.proxmox-tag-dark[style],
.x-panel-body span.proxmox-tag-dark[style],
.x-tree-view span.proxmox-tag-dark[style] {
    color: #000000 !important;
    text-shadow: none !important;
}

span.proxmox-tag-light,
span.proxmox-tag-light[style],
.x-grid-cell span.proxmox-tag-light[style],
.x-grid-cell-inner span.proxmox-tag-light[style],
div span.proxmox-tag-light[style],
.x-panel-body span.proxmox-tag-light[style],
.x-tree-view span.proxmox-tag-light[style] {
    color: #ffffff !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.6) !important;
}


/* ─── 05. ICONES VM/LXC RUNNING ──────────────────────────────
 * fa-desktop (VM) et fa-cube (LXC) en fonctionnement.
 * Icone noire avec triple drop-shadow cyan.
 * ──────────────────────────────────────────────────────────── */

.x-grid-item-container .fa-desktop,
.x-grid-item-container .fa-cube,
.x-tree-icon.fa-desktop, .x-tree-icon.fa-cube,
.x-tree-icon-leaf.fa-desktop, .x-tree-icon-leaf.fa-cube,
.x-tree-icon-custom.fa-desktop, .x-tree-icon-custom.fa-cube {
    color: #000000 !important;
    filter: drop-shadow(0 0 6px rgba(0,212,255,0.8))
            drop-shadow(0 0 10px rgba(0,180,255,0.5))
            brightness(1.3) !important;
    animation: none !important;
    background: transparent !important;
    background-color: transparent !important;
}

.x-grid-item:hover .fa-desktop.running,
.x-grid-item:hover .fa-cube.running {
    filter: drop-shadow(0 0 8px rgba(0,255,136,0.9))
            drop-shadow(0 0 12px rgba(0,200,120,0.6))
            brightness(1.4) !important;
}

.x-grid-item-selected .fa-desktop,
.x-grid-item-selected .fa-cube {
    filter: drop-shadow(0 0 10px rgba(0,230,255,0.95))
            drop-shadow(0 0 15px rgba(0,200,255,0.7))
            brightness(1.5) !important;
}


/* ─── 06. ICONES VM/LXC STOPPED ──────────────────────────────
 * Rouge neon #cc2244 avec glow rouge propre.
 * ──────────────────────────────────────────────────────────── */

.fa-desktop.stopped, .fa-cube.stopped,
.x-tree-icon.fa-desktop.stopped, .x-tree-icon.fa-cube.stopped,
.x-tree-icon-leaf.fa-desktop.stopped, .x-tree-icon-leaf.fa-cube.stopped,
.x-tree-icon-custom.fa-desktop.stopped, .x-tree-icon-custom.fa-cube.stopped,
.x-grid-item-container .fa-desktop.stopped,
.x-grid-item-container .fa-cube.stopped {
    color: #cc2244 !important;
    filter: drop-shadow(0 0 6px rgba(220,40,80,0.7))
            drop-shadow(0 0 10px rgba(200,30,60,0.4))
            brightness(1.4) !important;
}

.x-grid-item:hover .fa-desktop.stopped,
.x-grid-item:hover .fa-cube.stopped {
    filter: drop-shadow(0 0 8px rgba(255,50,90,0.9))
            drop-shadow(0 0 14px rgba(220,40,80,0.6))
            brightness(1.5) !important;
}


/* ─── 07. ICONES TEMPLATES ────────────────────────────────────
 * Violet lavande #9966aa. Fond force transparent sur l'element
 * ET ses pseudo-elements (::before/::after).
 * ──────────────────────────────────────────────────────────── */

.fa-file-o,
.fa-file-o::before, .fa-file-o::after,
.x-tree-icon.fa-file-o,
.x-tree-icon-leaf.fa-file-o,
.x-tree-icon-custom.fa-file-o,
div[class*="fa-file-o"],
div[class*="fa-file-o"]::before,
div[class*="fa-file-o"]::after,
.x-grid-item-container .fa-file-o {
    color: #9966aa !important;
    filter: drop-shadow(0 0 4px rgba(150,100,180,0.5)) brightness(1.2) !important;
    animation: none !important;
    background: transparent !important;
    background-color: transparent !important;
    background-image: none !important;
}

.x-grid-item:hover .fa-file-o {
    filter: drop-shadow(0 0 6px rgba(150,100,180,0.7)) brightness(1.3) !important;
}


/* ─── 08. NOEUDS CLUSTER (fa-server) ─────────────────────────
 * Cyan electrique #00ffff avec animation pulsante.
 * ──────────────────────────────────────────────────────────── */

.fa-server,
.x-grid-item-container .fa-server,
.x-tree-icon.fa-server,
.x-tree-icon-parent.fa-server {
    color: #00ffff !important;
    filter: drop-shadow(0 0 14px rgba(0,255,255,1))
            drop-shadow(0 0 22px rgba(0,240,255,0.9))
            drop-shadow(0 0 32px rgba(0,220,255,0.7))
            brightness(1.6) !important;
    animation: none !important;
}

.x-grid-item:hover .fa-server,
.x-tree-node:hover .fa-server {
    filter: drop-shadow(0 0 18px rgba(0,255,255,1))
            drop-shadow(0 0 28px rgba(50,255,255,1))
            drop-shadow(0 0 42px rgba(0,240,255,0.9))
            brightness(1.8) !important;
}

.x-grid-item-selected .fa-server,
.x-tree-node-selected .fa-server {
    filter: drop-shadow(0 0 22px rgba(0,255,255,1))
            drop-shadow(0 0 36px rgba(50,255,255,1))
            drop-shadow(0 0 52px rgba(0,240,255,1))
            brightness(2.0) !important;
    animation: iconServerGlowCyan 2.5s ease-in-out infinite !important;
}

@keyframes iconServerGlowCyan {
    0%, 100% {
        filter: drop-shadow(0 0 22px rgba(0,255,255,1))
                drop-shadow(0 0 36px rgba(50,255,255,0.9))
                brightness(2.0);
    }
    50% {
        filter: drop-shadow(0 0 30px rgba(50,255,255,1))
                drop-shadow(0 0 44px rgba(0,255,255,1))
                brightness(2.3);
    }
}


/* ─── 09. DATACENTER (fa-building) ───────────────────────────
 * Blanc pur #ffffff avec halo blanc + animation.
 * ──────────────────────────────────────────────────────────── */

.x-grid-item-container .fa-building,
.x-tree-icon.fa-building,
.x-tree-icon-parent.fa-building,
.x-tree-icon-parent-expanded.fa-building,
.x-tree-icon-custom.fa-building {
    color: #ffffff !important;
    filter: drop-shadow(0 0 8px rgba(255,255,255,0.9))
            drop-shadow(0 0 12px rgba(255,255,255,0.6))
            drop-shadow(0 0 16px rgba(255,255,255,0.4))
            brightness(1.3) !important;
    animation: none !important;
}

.x-grid-item:hover .fa-building {
    filter: drop-shadow(0 0 10px rgba(255,255,255,1))
            drop-shadow(0 0 16px rgba(255,255,255,0.8))
            drop-shadow(0 0 24px rgba(255,255,255,0.6))
            brightness(1.5) !important;
}

.x-grid-item-selected .fa-building {
    filter: drop-shadow(0 0 14px rgba(255,255,255,1))
            drop-shadow(0 0 22px rgba(255,255,255,0.9))
            drop-shadow(0 0 32px rgba(255,255,255,0.7))
            brightness(1.6) !important;
    animation: iconDatacenterGlowWhite 2s ease-in-out infinite !important;
}

@keyframes iconDatacenterGlowWhite {
    0%, 100% {
        filter: drop-shadow(0 0 14px rgba(255,255,255,0.9))
                drop-shadow(0 0 22px rgba(255,255,255,0.8))
                brightness(1.6);
    }
    50% {
        filter: drop-shadow(0 0 18px rgba(255,255,255,1))
                drop-shadow(0 0 28px rgba(255,255,255,0.9))
                brightness(1.8);
    }
}


/* ─── 10. ICONE CEPH (image PNG) ─────────────────────────────
 * brightness(0) rend l'image noire, invert(1) la passe en blanc.
 * ──────────────────────────────────────────────────────────── */

.fa-ceph::before,
.fa-ceph:before {
    filter: brightness(0) invert(1) !important;
}


/* ─── 11. HOVER ET SELECTION SUR LES LIGNES ────────────────── */

.x-grid-item:hover {
    background: linear-gradient(90deg, rgba(0,200,255,0.25), rgba(0,180,255,0.15)) !important;
    border-left: 4px solid #00d4ff !important;
    box-shadow: inset 0 0 20px rgba(0,212,255,0.3), 0 0 15px rgba(0,200,255,0.4) !important;
    transition: all 0.3s ease !important;
}

.x-grid-item:hover .x-grid-cell { color: #fff !important; }

.x-grid-item-selected {
    background: linear-gradient(90deg, rgba(0,212,255,0.4), rgba(0,180,255,0.3)) !important;
    border-left: 6px solid #00d4ff !important;
    box-shadow: inset 0 0 30px rgba(0,220,255,0.5), 0 0 25px rgba(0,212,255,0.8) !important;
}

.x-grid-item-selected .x-grid-cell {
    color: #fff !important;
    font-weight: 700 !important;
}


/* ─── 12. EN-TETES PANNEAUX ET FENETRES ────────────────────── */

.x-panel-header, .x-window-header {
    background: linear-gradient(135deg, rgba(20,40,80,0.9), rgba(30,60,100,0.85), rgba(15,45,85,0.88)) !important;
    border-bottom: 2px solid rgba(0,212,255,0.7) !important;
    box-shadow: 0 3px 20px rgba(0,212,255,0.4) !important;
}

.x-panel-header *, .x-window-header * {
    color: #fff !important;
    text-shadow: 0 0 12px rgba(0,230,255,0.9) !important;
}

.x-column-header, .x-grid-header-ct, .x-column-header-inner {
    background: linear-gradient(180deg, rgba(20,40,80,0.9), rgba(15,35,70,0.85)) !important;
    border-bottom: 2px solid rgba(0,212,255,0.6) !important;
}

.x-column-header-text {
    color: #e8f4ff !important;
    text-shadow: 0 0 10px rgba(0,230,255,0.7) !important;
    font-weight: 700 !important;
}


/* ─── 13. BARRE SUPERIEURE ─────────────────────────────────── */

body > div:first-of-type {
    background: linear-gradient(90deg, rgba(15,25,45,0.96), rgba(20,35,60,0.96), rgba(15,30,50,0.96)) !important;
    border-bottom: 3px solid transparent !important;
    border-image: linear-gradient(90deg, #00d4ff 0%, #0099ff 50%, #00d4ff 100%) 1 !important;
    box-shadow: 0 4px 25px rgba(0,212,255,0.4) !important;
}


/* ─── 14. MENU CONTEXTUEL + BULK ACTIONS ───────────────────── */

.x-menu {
    background: rgba(15,25,45,0.96) !important;
    backdrop-filter: blur(15px) !important;
    border: 2px solid rgba(0,212,255,0.5) !important;
    box-shadow: 0 12px 40px rgba(0,0,0,0.7), 0 0 30px rgba(0,212,255,0.3) !important;
    border-radius: 10px !important;
}

.x-menu-item {
    border-radius: 6px !important;
    margin: 2px 4px !important;
    transition: all 0.3s ease !important;
}

.x-menu-item .x-menu-item-text {
    color: #e8f4ff !important;
    text-shadow: 0 0 8px rgba(0,212,255,0.5) !important;
    font-weight: 600 !important;
}

.x-menu-item-active,
.x-menu-item.x-menu-item-active,
.x-menu-item:hover {
    background: linear-gradient(90deg, rgba(0,200,255,0.25), rgba(0,180,255,0.15)) !important;
    border-radius: 6px !important;
}

.x-menu-item:hover .x-menu-item-text,
.x-menu-item-active .x-menu-item-text {
    color: #fff !important;
    text-shadow: 0 0 12px rgba(0,230,255,0.9) !important;
    font-weight: 700 !important;
}

.x-menu-item .x-menu-item-icon {
    color: #e8f4ff !important;
    filter: drop-shadow(0 0 6px rgba(0,212,255,0.6)) !important;
}

.x-menu-item .fa-play,
.x-menu-item .x-menu-item-icon.fa-play {
    color: #00cc66 !important;
    filter: drop-shadow(0 0 6px rgba(0,200,100,0.6)) !important;
}

.x-menu-item .fa-stop,
.x-menu-item .x-menu-item-icon.fa-stop {
    color: #cc3344 !important;
    filter: drop-shadow(0 0 6px rgba(200,50,70,0.6)) !important;
}

.x-menu-item .fa-pause,
.x-menu-item .x-menu-item-icon.fa-pause {
    color: #cc8833 !important;
    filter: drop-shadow(0 0 6px rgba(200,130,50,0.6)) !important;
}

.x-menu-item .fa-power-off,
.x-menu-item .x-menu-item-icon.fa-power-off {
    color: #cc3344 !important;
    filter: drop-shadow(0 0 6px rgba(200,50,70,0.6)) !important;
}


/* ─── 15. BOUTONS BARRE SUPERIEURE ─────────────────────────── */

.x-toolbar .x-btn, .x-docked-top .x-btn {
    background: linear-gradient(135deg, rgba(15,25,50,0.9), rgba(20,35,65,0.85)) !important;
    border: 1px solid rgba(0,212,255,0.3) !important;
    border-radius: 6px !important;
    transition: all 0.3s ease !important;
}

.x-toolbar .x-btn:hover, .x-docked-top .x-btn:hover {
    background: linear-gradient(135deg, rgba(20,35,65,0.95), rgba(25,45,80,0.9)) !important;
    border-color: rgba(0,212,255,0.6) !important;
    box-shadow: 0 0 12px rgba(0,212,255,0.4) !important;
}

.x-toolbar .x-btn .x-btn-inner, .x-docked-top .x-btn .x-btn-inner {
    color: #e8f4ff !important;
    font-weight: 600 !important;
}

.x-toolbar .x-btn:hover .x-btn-inner {
    color: #fff !important;
    text-shadow: 0 0 10px rgba(0,230,255,0.8) !important;
}

.x-btn-success {
    background: rgba(0,200,120,0.5) !important;
    border: 2px solid #00ff88 !important;
}
.x-btn-success * { color: #fff !important; font-weight: bold !important; }

.x-btn-danger {
    background: rgba(220,50,80,0.5) !important;
    border: 2px solid #ff4466 !important;
}
.x-btn-danger * { color: #fff !important; font-weight: bold !important; }

.x-btn-split-right {
    border-left: 1px solid rgba(0,212,255,0.3) !important;
}


/* ─── 16. NAVIGATION LATERALE (treelist) ───────────────────── */

.x-treelist, .x-treelist-container, .x-treelist-row-over,
.x-treelist-item-wrap, .pve-nav-tree, .x-treelist-navigation {
    background: linear-gradient(180deg, rgba(15,25,45,0.95), rgba(20,30,50,0.92)) !important;
}

.x-treelist-item, .x-treelist-row {
    background: transparent !important;
    border-left: 3px solid transparent !important;
    transition: all 0.3s ease !important;
    margin: 2px 0 !important;
}

.x-treelist-item-over, .x-treelist-row-over,
.x-treelist-item:hover, .x-treelist-row:hover {
    background: linear-gradient(90deg, rgba(0,200,255,0.25), rgba(0,180,255,0.15)) !important;
    border-left: 4px solid #00d4ff !important;
}

.x-treelist-item-selected, .x-treelist-row-selected {
    background: linear-gradient(90deg, rgba(0,212,255,0.35), rgba(0,190,255,0.25)) !important;
    border-left: 5px solid #00d4ff !important;
    box-shadow: inset 0 0 30px rgba(0,220,255,0.5), 0 0 15px rgba(0,212,255,0.6) !important;
}

.x-treelist-item-text {
    color: #e8f4ff !important;
    text-shadow: 0 0 10px rgba(0,212,255,0.5) !important;
    font-weight: 600 !important;
}

.x-treelist-item-selected .x-treelist-item-text {
    color: #fff !important;
    text-shadow: 0 0 15px rgba(0,230,255,0.9) !important;
    font-weight: 700 !important;
}

.x-treelist-item-icon, .x-treelist-item-icon.fa {
    color: #fff !important;
    filter: drop-shadow(0 0 8px rgba(255,255,255,0.6)) !important;
}

.x-treelist-item-selected .x-treelist-item-icon {
    filter: drop-shadow(0 0 12px rgba(255,255,255,0.9)) !important;
}

.x-treelist::before, .x-treelist-container::before {
    content: "";
    position: absolute; top: 0; left: 0; right: 0; height: 3px;
    background: linear-gradient(90deg, #00d4ff 0%, #0099ff 50%, #00d4ff 100%) !important;
    background-size: 200% 100% !important;
    animation: elecBorder 3s linear infinite !important;
    z-index: 10;
}

@keyframes elecBorder {
    0%   { background-position: 0% 50%; }
    100% { background-position: 200% 50%; }
}

.x-panel.x-box-layout-ct, .x-box-inner {
    background: linear-gradient(180deg, rgba(15,25,45,0.95), rgba(20,30,50,0.92)) !important;
}


/* ─── 17. ONGLETS (TABS) ACTIF/INACTIF ───────────────────────
 * Onglet actif : blanc lumineux + fond bleu + bordure cyan.
 * Onglet inactif : gris-bleu discret.
 * ──────────────────────────────────────────────────────────── */

.x-tab.x-tab-active,
.x-tab.x-tab-default.x-tab-active {
    background: linear-gradient(180deg, rgba(0,212,255,0.3), rgba(0,180,255,0.15)) !important;
    border-bottom: 2px solid #00d4ff !important;
}

.x-tab.x-tab-active .x-tab-inner,
.x-tab.x-tab-default.x-tab-active .x-tab-inner {
    color: #ffffff !important;
    text-shadow: 0 0 10px rgba(0,230,255,0.8) !important;
    font-weight: 700 !important;
}

.x-tab .x-tab-inner,
.x-tab.x-tab-default .x-tab-inner {
    color: #70a8c8 !important;
    text-shadow: none !important;
    font-weight: 500 !important;
}

.x-tab:hover .x-tab-inner {
    color: #b0d8f0 !important;
}


/* ─── 18. CHAMPS ET FORMULAIRES ──────────────────────────────── */

.x-btn-inner {
    color: #e8f4ff !important;
    font-weight: 600 !important;
}

input, input[type="text"], input[type="password"], select, textarea {
    background: rgba(20,30,50,0.8) !important;
    border: 1px solid rgba(0,212,255,0.4) !important;
    color: #e8f4ff !important;
}

input:focus, select:focus, textarea:focus {
    border-color: #00d4ff !important;
    box-shadow: 0 0 10px rgba(0,212,255,0.5) !important;
}

.x-form-item-label, .x-form-item-label-text, .x-panel-body label {
    color: #e8f4ff !important;
}

.x-btn-default-toolbar-small {
    background: linear-gradient(135deg, rgba(15,25,45,0.9), rgba(20,35,60,0.85)) !important;
    border: 1px solid rgba(0,212,255,0.4) !important;
}

.x-btn-default-toolbar-small:hover {
    background: linear-gradient(135deg, rgba(20,35,60,0.95), rgba(25,45,75,0.9)) !important;
    border-color: rgba(0,212,255,0.6) !important;
}

.x-boundlist-default {
    background: rgba(15,25,45,0.95) !important;
    border: 1px solid rgba(0,212,255,0.5) !important;
}

.x-boundlist-item { color: #e8f4ff !important; }

.x-boundlist-item-over {
    background: linear-gradient(90deg, rgba(0,200,255,0.25), rgba(0,180,255,0.15)) !important;
}

.x-boundlist-selected {
    background: linear-gradient(90deg, rgba(0,212,255,0.4), rgba(0,180,255,0.3)) !important;
}


/* ─── 19. SCROLLBAR ──────────────────────────────────────────── */

::-webkit-scrollbar { width: 12px; background: #0a0e1a; }

::-webkit-scrollbar-thumb {
    background: linear-gradient(180deg, #00d4ff, #0099ff, #00d4ff) !important;
    border-radius: 8px !important;
}

::-webkit-scrollbar-thumb:hover {
    box-shadow: 0 0 20px rgba(0,230,255,1) !important;
}


/* ─── 20. BARRES DE PROGRESSION CPU/RAM/DISQUE ───────────────── */

.x-progress, .x-progress-default {
    background: rgba(15,25,45,0.8) !important;
    border: 1px solid rgba(0,212,255,0.3) !important;
    border-radius: 4px !important;
}

.x-progress-bar, .x-progress-bar-default {
    background: linear-gradient(90deg,
        rgba(0,212,255,0.8) 0%, rgba(0,180,255,0.9) 40%,
        rgba(0,255,136,0.8) 60%, rgba(255,200,0,0.9) 80%,
        rgba(255,68,102,0.9) 95%) !important;
    border-radius: 3px !important;
}

.x-progress-text, .x-progress-text-back {
    color: #fff !important;
    text-shadow: 0 1px 3px rgba(0,0,0,0.8) !important;
    font-weight: 700 !important;
}


/* ─── 21. CONSOLE SHELL / XTERM ──────────────────────────────── */

.pve-xtermjs,
.x-panel-body iframe[src*="xtermjs"],
.x-panel-body iframe[src*="consoletype"] {
    border: 2px solid rgba(0,212,255,0.3) !important;
    border-radius: 6px !important;
    box-shadow: 0 0 15px rgba(0,212,255,0.2) !important;
}

.x-autocontainer-innerCt iframe {
    border: 2px solid rgba(0,212,255,0.25) !important;
    border-radius: 4px !important;
}


/* ─── 22. FENETRES MODALES / POPUPS ──────────────────────────── */

.x-window {
    background: rgba(12,20,40,0.97) !important;
    border: 2px solid rgba(0,212,255,0.5) !important;
    border-radius: 10px !important;
    box-shadow: 0 0 30px rgba(0,212,255,0.3), 0 20px 60px rgba(0,0,0,0.6) !important;
}

.x-window-header { border-radius: 8px 8px 0 0 !important; }

.x-window-header-title .x-title-text {
    color: #fff !important;
    text-shadow: 0 0 12px rgba(0,230,255,0.8) !important;
    font-weight: 700 !important;
}

.x-window-header .x-tool-close { color: #ff6688 !important; }

.x-window-header .x-tool-close:hover {
    color: #ff4466 !important;
    filter: drop-shadow(0 0 8px rgba(255,68,102,0.8)) !important;
}

.x-window-body { background: rgba(15,25,45,0.95) !important; }

.x-window .x-toolbar-footer .x-btn {
    background: linear-gradient(135deg, rgba(15,30,55,0.9), rgba(20,40,70,0.85)) !important;
    border: 1px solid rgba(0,212,255,0.4) !important;
    border-radius: 6px !important;
}

.x-window .x-toolbar-footer .x-btn:hover {
    border-color: rgba(0,212,255,0.7) !important;
    box-shadow: 0 0 10px rgba(0,212,255,0.4) !important;
}

.x-mask { background: rgba(5,10,20,0.7) !important; }

.x-message-box {
    background: rgba(12,20,40,0.97) !important;
    border: 2px solid rgba(0,212,255,0.5) !important;
    border-radius: 10px !important;
}


/* ─── 23. TOOLTIPS ───────────────────────────────────────────── */

.x-tip, .x-tip-default, .x-tooltip {
    background: rgba(12,20,40,0.96) !important;
    border: 1px solid rgba(0,212,255,0.5) !important;
    border-radius: 6px !important;
    box-shadow: 0 0 15px rgba(0,212,255,0.3), 0 4px 12px rgba(0,0,0,0.5) !important;
}

.x-tip-body, .x-tip-body-default, .x-tooltip-body {
    color: #e8f4ff !important;
    font-weight: 500 !important;
}

.x-tip-header, .x-tip-header-title {
    color: #fff !important;
    font-weight: 700 !important;
}


/* ─── 24. GRAPHIQUES RRD ─────────────────────────────────────── */

.proxmox-rrd-chart, .pve-rrds,
img[src*="rrd"], img[src*="graph"],
.x-panel-body img[src*="api2"] {
    filter: invert(1) hue-rotate(180deg) saturate(1.5) brightness(0.85) contrast(1.1) !important;
    border: 1px solid rgba(0,212,255,0.2) !important;
    border-radius: 4px !important;
}


/* ─── 25. LOGO PROXMOX TEXTE NEON V4 (ORBITRON) ─────────────
 * On cache l'image PNG et on la remplace par du texte CSS pur
 * via ::before. Animation glow pulsant (2.5s ease-in-out).
 * Fallback : Consolas / monospace si Orbitron non disponible.
 * ──────────────────────────────────────────────────────────── */

a[id^="proxmoxlogo"] img,
img[src*="proxmox_logo"], img[alt*="Proxmox"] {
    display: none !important;
}

a[id^="proxmoxlogo"] {
    font-size: 0 !important;
    display: inline-flex !important;
    align-items: center !important;
}

a[id^="proxmoxlogo"]::before {
    content: "PROXMOX" !important;
    font-family: 'Orbitron', 'Consolas', 'Lucida Console', monospace !important;
    font-size: 22px !important;
    font-weight: 900 !important;
    letter-spacing: 3px !important;
    color: #00e5ff !important;
    animation: logoPulseV4 2.5s ease-in-out infinite !important;
}

@keyframes logoPulseV4 {
    0%, 100% {
        text-shadow:
            0 0 8px rgba(0,230,255,0.7),
            0 0 16px rgba(0,212,255,0.4),
            0 0 30px rgba(0,180,255,0.2);
    }
    50% {
        text-shadow:
            0 0 14px rgba(0,230,255,1),
            0 0 28px rgba(0,212,255,0.8),
            0 0 50px rgba(0,180,255,0.5),
            0 0 80px rgba(0,150,255,0.3);
    }
}


/* ─── 26. BADGE ETABLISSEMENT + SEPARATEUR ───────────────────
 * Separateur lumineux cyan entre le logo et le badge.
 * ──────────────────────────────────────────────────────────── */

#versioninfo-innerCt {
    font-size: 0 !important;
    display: inline-block !important;
    margin-left: 20px !important;
    padding-left: 20px !important;
    border-left: 2px solid transparent !important;
    border-image: linear-gradient(180deg, transparent, rgba(0,212,255,0.6), transparent) 1 !important;
}

#versioninfo-innerCt::before {
    content: "@@BADGE@@" !important;
    font-family: 'Rajdhani', 'Orbitron', 'Arial Black', sans-serif !important;
    font-size: 16px !important;
    font-weight: 900 !important;
    letter-spacing: 2px !important;
    text-transform: uppercase !important;
    white-space: nowrap !important;
    display: inline-block !important;
    background: linear-gradient(90deg, #00e5ff 0%, #00ffaa 50%, #00e5ff 100%) !important;
    background-size: 200% 100% !important;
    -webkit-background-clip: text !important;
    -webkit-text-fill-color: transparent !important;
    background-clip: text !important;
    filter: drop-shadow(0 0 15px rgba(0,230,255,0.9))
            drop-shadow(0 0 25px rgba(0,230,255,0.6)) !important;
    animation: textGrad 4s linear infinite !important;
    padding: 6px 14px !important;
    border: 2px solid rgba(0,230,255,0.4) !important;
    border-radius: 8px !important;
    background-color: rgba(0,230,255,0.08) !important;
}

@keyframes textGrad {
    0%   { background-position: 0% 50%; }
    50%  { background-position: 100% 50%; }
    100% { background-position: 200% 50%; }
}


/* ─── 27. LIGNES ERREUR / INVALIDE (Cluster log) ────────────
 * Proxmox applique un fond orange sur les taches en erreur
 * via .proxmox-invalid-row. On remplace par un style cyberpunk
 * coherent : fond sombre avec bordure rouge + texte rose-rouge.
 * ──────────────────────────────────────────────────────────── */

.proxmox-invalid-row {
    background: linear-gradient(90deg, rgba(255,60,80,0.15), rgba(255,60,80,0.05)) !important;
    border-left: 3px solid rgba(255,80,100,0.6) !important;
}

.proxmox-invalid-row td,
.proxmox-invalid-row .x-grid-cell,
.proxmox-invalid-row .x-grid-cell-inner,
.proxmox-invalid-row div {
    color: #ff6b7f !important;
    text-shadow: 0 0 6px rgba(255,80,100,0.3) !important;
    font-weight: 600 !important;
}


/* ─── 28. ONGLETS TASKS / CLUSTER LOG ────────────────────────
 * Onglet inactif : fond transparent, bordure subtile.
 * Onglet actif : fond bleu neon, bordure cyan, texte vif.
 * ──────────────────────────────────────────────────────────── */

div[id^="pveStatusPanel"] .x-tab {
    background: transparent !important;
    border: 1px solid rgba(0,212,255,0.2) !important;
    border-radius: 4px 4px 0 0 !important;
}

div[id^="pveStatusPanel"] .x-tab .x-tab-inner {
    color: rgba(0,212,255,0.35) !important;
    text-shadow: none !important;
    font-weight: 500 !important;
}

div[id^="pveStatusPanel"] .x-tab:hover {
    background: rgba(0,212,255,0.1) !important;
    border-color: rgba(0,212,255,0.4) !important;
}

div[id^="pveStatusPanel"] .x-tab:hover .x-tab-inner {
    color: rgba(0,212,255,0.6) !important;
}

div[id^="pveStatusPanel"] .x-tab.x-tab-active {
    background: linear-gradient(180deg, rgba(0,212,255,0.25), rgba(0,180,255,0.1)) !important;
    border-color: rgba(0,212,255,0.5) !important;
    border-bottom: 2px solid #00d4ff !important;
}

div[id^="pveStatusPanel"] .x-tab.x-tab-active .x-tab-inner {
    color: #00d4ff !important;
    text-shadow: 0 0 8px rgba(0,212,255,0.5) !important;
    font-weight: 700 !important;
}


/* ─── 29. COPYRIGHT DISCRET ──────────────────────────────────
 * Affiche dans la barre Tasks/Cluster log, aligne a droite.
 * Texte tres discret (opacite 25%) pour ne pas gene.
 * Attribution CC BY-NC-SA : a conserver en cas de rediffusion du theme.
 * Aucune option ne la retire (--badge, lui, alimente la SECTION 26, le badge
 * du haut) : pour s'en passer, supprimer ce bloc (08/10/2026).
 * ──────────────────────────────────────────────────────────── */

div[id^="pveStatusPanel-"][class~="x-panel"] .x-tab-bar {
    position: relative !important;
    overflow: visible !important;
}

div[id^="pveStatusPanel-"][class~="x-panel"] .x-tab-bar::after {
    content: "\00A9  2025-2026 D. SCONTRINO" !important;
    position: absolute !important;
    right: 12px !important;
    top: 50% !important;
    transform: translateY(-50%) !important;
    font-size: 10px !important;
    font-weight: 400 !important;
    letter-spacing: 0.5px !important;
    color: rgba(0,212,255,0.25) !important;
    text-shadow: none !important;
    pointer-events: none !important;
    white-space: nowrap !important;
    z-index: 10 !important;
}


/* ─── 30. MESSAGE D'ACCUEIL (option --message) ───────────────
 * Fenetre affichee apres la connexion si l'option est activee.
 * ──────────────────────────────────────────────────────────── */

.tpc-message .x-window-body,
.tpc-message .x-autocontainer-innerCt {
    background: rgba(12,20,40,0.97) !important;
}

.tpc-message-contenu,
.tpc-message-contenu p,
.tpc-message-contenu li {
    color: #e8f4ff !important;
    font-size: 14px !important;
    line-height: 1.6 !important;
}

.tpc-message-contenu h1, .tpc-message-contenu h2, .tpc-message-contenu h3 {
    color: #00e5ff !important;
    text-shadow: 0 0 10px rgba(0,230,255,0.6) !important;
    margin: 0.4em 0 0.5em 0 !important;
}

.tpc-message-contenu strong, .tpc-message-contenu b { color: #ffffff !important; }
.tpc-message-contenu a { color: #00e5ff !important; }
.tpc-message-contenu ul, .tpc-message-contenu ol { padding-left: 1.4em !important; }
FIN_CSS
}


###################################################################
#   SECTION 9 : OPTIONS PÉDAGOGIQUES (fichier JavaScript séparé)  #
###################################################################

# Message d'accueil : fichier .html (utilisé tel quel) ou texte brut
# (caractères spéciaux neutralisés, retours à la ligne conservés).
message_en_html() {
    local f="$1"
    case "${f,,}" in
        *.html|*.htm) cat "$f" ;;
        *) perl -CSD -pe 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; s/"/&quot;/g; s/\n/<br>\n/' "$f" ;;
    esac
}

chaine_js() {   # texte (entrée standard) → littéral JavaScript sûr
    perl -MJSON::PP -e 'local $/; my $s = <STDIN>; $s = "" unless defined $s;
        utf8::decode($s); my $j = JSON::PP->new->ascii->allow_nonref->encode($s);
        $j =~ s{</}{<\\/}g; print $j;'
}

generer_js() {   # OPT_MESSAGE est déjà en HTML (voir preparer_message)
    local message="null" titre cle clone="false"
    if [[ -n "$OPT_MESSAGE" ]]; then
        message="$(chaine_js < "$OPT_MESSAGE")"
    fi
    titre="$(printf '%s' "$OPT_TITRE_MESSAGE" | chaine_js)"
    if (( OPT_CLONE )); then clone="true"; fi
    cle="$(printf '%s|%s' "$message" "$titre" | sha256sum | cut -c1-16)"
    js_corps | sed -e "s|@@CLONE@@|${clone}|" -e "s|@@CLE@@|\"${cle}\"|" \
        | TPC_TITRE="$titre" TPC_MESSAGE="$message" perl -pe '
            BEGIN { $t = $ENV{TPC_TITRE}; $m = $ENV{TPC_MESSAGE} }
            s/\@\@TITRE\@\@/$t/; s/\@\@MESSAGE\@\@/$m/;'
}

# Le message est converti UNE fois en HTML (texte brut : caractères neutralisés),
# puis c'est ce HTML qui est conservé dans /opt et envoyé aux autres nœuds.
preparer_message() {
    [[ -n "$OPT_MESSAGE" ]] || return 0
    [[ "$OPT_MESSAGE" == "$MESSAGE_INSTALLE" ]] && return 0
    [[ -r "$OPT_MESSAGE" ]] || { erreur "message illisible : ${OPT_MESSAGE}"; OPT_MESSAGE=""; return 1; }
    message_en_html "$OPT_MESSAGE" > "${TMP_LOCAL}/message.html" \
        || { erreur "conversion du message impossible"; OPT_MESSAGE=""; return 1; }
    OPT_MESSAGE="${TMP_LOCAL}/message.html"
}

js_corps() {
cat << 'FIN_JS'
/* ═══════════════════════════════════════════════════════════════
 * THÈME PROXMOX CYBERPUNK — options pédagogiques
 * Fichier généré par install_theme_proxmox.sh : ne pas le modifier,
 * relancer le script. Chaque bloc est protégé (try/catch) : une
 * erreur ici ne doit jamais empêcher l'interface de fonctionner.
 * ═══════════════════════════════════════════════════════════════ */
(function () {
    // PAS de 'use strict' ici : this.callParent() d'ExtJS ne fonctionne pas en mode strict.
    var CFG = {
        cle: @@CLE@@,
        cloneIntegral: @@CLONE@@,
        titre: @@TITRE@@,
        message: @@MESSAGE@@
    };
    var signaler = function (quoi, e) {
        if (window.console && console.error) { console.error('theme-proxmox-cyberpunk (' + quoi + ') :', e); }
    };

    /* 1) Clonage d'un MODÈLE par un compte non administrateur : seul le
     *    « Clone intégral » est proposé. Un clone lié doit rester sur le
     *    stockage du modèle, où les étudiants n'ont en général pas le droit
     *    d'écrire : il échouait alors toujours (erreur de permission).
     *    Purement visuel : les droits côté serveur ne changent pas. */
    if (CFG.cloneIntegral) {
        try {
            Ext.define('ThemeProxmoxCyberpunk.override.CloneIntegral', {
                override: 'PVE.window.Clone',
                initComponent: function () {
                    this.callParent(arguments);
                    try {
                        if (!this.isTemplate) { return; }
                        var caps = Ext.state.Manager.get('GuiCap') || {};
                        var admin = Proxmox.UserName === 'root@pam' ||
                            !!(caps.nodes && caps.nodes['Sys.Modify']) ||
                            !!(caps.dc && caps.dc['Sys.Modify']);
                        if (admin) { return; }
                        var sel = this.lookupReference('clonemodesel');
                        if (!sel) { return; }
                        sel.setComboItems([['copy', gettext('Full Clone')]]);
                        sel.setValue('copy');
                    } catch (e) { signaler('clone', e); }
                }
            });
        } catch (e) { signaler('clone (définition)', e); }
    }

    /* 2) Message d'accueil : affiché après la connexion, une fois par
     *    session du navigateur (et de nouveau si le message change). */
    if (CFG.message) {
        Ext.onReady(function () {
            var essais = 0, stable = 0;
            var minuteur = setInterval(function () {
                essais += 1;
                if (essais > 7200) { clearInterval(minuteur); return; }
                // On attend : utilisateur connecté, interface dessinée, aucune
                // fenêtre modale ouverte (connexion...), état stable pendant 2 s.
                try {
                    var connecte = typeof Proxmox !== 'undefined' && !!Proxmox.UserName;
                    var vue = Ext.ComponentQuery.query('viewport')[0];
                    var occupe = Ext.ComponentQuery.query('window[modal=true]').some(function (w) {
                        return w.isVisible();
                    });
                    if (!connecte || !vue || !vue.rendered || occupe) { stable = 0; return; }
                } catch (e) { stable = 0; return; }
                stable += 1;
                if (stable < 2) { return; }
                clearInterval(minuteur);
                try {
                    try {
                        if (window.sessionStorage.getItem('theme-proxmox-message') === CFG.cle) { return; }
                        window.sessionStorage.setItem('theme-proxmox-message', CFG.cle);
                    } catch (e) { /* stockage indisponible : on affiche quand même */ }
                    var taille = Ext.getBody().getViewSize();
                    Ext.create('Ext.window.Window', {
                        title: CFG.titre,
                        cls: 'tpc-message',
                        modal: true,
                        constrain: true,
                        width: Math.min(760, Math.round(taille.width * 0.92)),
                        maxHeight: Math.round(taille.height * 0.85),
                        scrollable: true,
                        bodyPadding: 22,
                        html: '<div class="tpc-message-contenu">' + CFG.message + '</div>',
                        buttons: [{
                            text: "J'ai compris",
                            handler: function (b) { b.up('window').close(); }
                        }],
                        listeners: {
                            show: function (w) {
                                Ext.defer(function () {
                                    try { w.updateLayout(); w.center(); } catch (e) { signaler('message', e); }
                                }, 300);
                            }
                        }
                    }).show();
                } catch (e) { signaler('message', e); }
            }, 1000);
        });
    }
})();
FIN_JS
}


###################################################################
#                 SECTION 10 : INSTALLATION LOCALE                #
###################################################################

lignes_template() {   # lignes à insérer avant </head>
    local v_css="$1" v_js="$2"
    printf '    <link rel="stylesheet" type="text/css" href="%s?v=%s" /><!-- %s : ajoute par install_theme_proxmox.sh -->\n' \
        "$URL_CSS" "$v_css" "$MARQUE"
    if [[ -n "$v_js" ]]; then
        printf '    <script type="text/javascript" src="%s?v=%s"></script><!-- %s : ajoute par install_theme_proxmox.sh -->\n' \
            "$URL_JS" "$v_js" "$MARQUE"
    fi
}

# Construit le nouveau index.html.tpl : nos anciennes lignes retirées, les
# nouvelles insérées juste avant </head> (après TOUTES les feuilles de Proxmox,
# y compris le thème sombre, pour que le thème garde la main).
construire_template() {   # $1 = source, $2 = destination, $3 = lignes
    TPC_LIGNES="$3" awk -v marque="$MARQUE" '
        index($0, marque) { next }
        /<\/head>/ && !fait { printf "%s", ENVIRON["TPC_LIGNES"]; fait = 1 }
        { print }
        END { if (!fait) exit 3 }' "$1" > "$2"
}

appliquer_abonnement() {   # neutralise (1) ou rétablit (0) la fenêtre d'abonnement
    local voulu="$1" etat t
    etat="$(etat_abonnement)"
    if [[ "$voulu" -eq 1 ]]; then
        case "$etat" in
            neutralise)
                if [[ "$CONF_ABO_PAR_SCRIPT" == "1" ]]; then
                    ok "Fenêtre d'abonnement : déjà neutralisée"
                else
                    ok "Fenêtre d'abonnement : déjà neutralisée par une autre installation (ce script n'y touchera pas)"
                fi
                return 0 ;;
            introuvable|absent)
                attention "Fenêtre d'abonnement : motif introuvable dans proxmoxlib.js (version différente ?) — conservée."
                return 0 ;;
        esac
        if (( SIMULATION )); then simule "neutraliserait la fenêtre « No valid subscription » (proxmoxlib.js)"; return 0; fi
        sauvegarder "$TOOLKIT_JS" || return 1
        t="$(mktemp -p "$TMP_LOCAL")"
        perl -0777 -pe 's/(?<!void\(\{ \/\/)(Ext\.Msg\.show\(\{\s+title: gettext\(.No valid subscription.\),)/void({ \/\/$1/g' \
            "$TOOLKIT_JS" > "$t"
        if ! cmp -s "$t" "$TOOLKIT_JS" && remplacer_fichier "$t" "$TOOLKIT_JS"; then
            CONF_ABO_PAR_SCRIPT=1
            ok "Fenêtre « No valid subscription » neutralisée (proxmoxlib.js)"
            journal "abonnement : fenêtre neutralisée"
        else
            erreur "neutralisation de la fenêtre d'abonnement impossible"
        fi
        rm -f "$t"
    else
        if [[ "$etat" != "neutralise" ]]; then return 0; fi
        if [[ "$CONF_ABO_PAR_SCRIPT" != "1" ]]; then
            info "Fenêtre d'abonnement neutralisée par autre chose que ce script : laissée telle quelle."
            return 0
        fi
        if (( SIMULATION )); then simule "rétablirait la fenêtre « No valid subscription » (proxmoxlib.js)"; return 0; fi
        sauvegarder "$TOOLKIT_JS" || return 1
        t="$(mktemp -p "$TMP_LOCAL")"
        perl -0777 -pe 's/void\(\{ \/\/(Ext\.Msg\.show\(\{\s+title: gettext\(.No valid subscription.\),)/$1/g' \
            "$TOOLKIT_JS" > "$t"
        if remplacer_fichier "$t" "$TOOLKIT_JS"; then
            CONF_ABO_PAR_SCRIPT=0
            if [[ "$(etat_paquet "$TOOLKIT_JS")" == "origine" ]]; then
                ok "proxmoxlib.js rétabli : identique au fichier d'origine du paquet (md5 vérifié)"
            else
                attention "proxmoxlib.js rétabli, mais il diffère encore du paquet (autre modification, pas de ce script)."
            fi
            journal "abonnement : fenêtre rétablie"
        else
            erreur "rétablissement de proxmoxlib.js impossible"
        fi
        rm -f "$t"
    fi
}

installer_crochet_apt() {
    local contenu t
    contenu="// Thème Proxmox cyberpunk (${VERSION_COURTE}) : réapplique le thème après une mise à jour
// de Proxmox (pve-manager réécrit index.html.tpl). Retrait propre :
//   ${SCRIPT_INSTALLE} --desinstaller
DPkg::Post-Invoke { \"test ! -x ${SCRIPT_INSTALLE} || ${SCRIPT_INSTALLE} --reappliquer || true\"; };"
    if [[ -f "$CROCHET_APT" ]] && [[ "$(cat "$CROCHET_APT")" == "$contenu" ]]; then
        ok "Crochet APT déjà en place (le thème survivra aux mises à jour)"
        return 0
    fi
    if (( SIMULATION )); then simule "créerait le crochet APT ${CROCHET_APT}"; return 0; fi
    t="$(mktemp -p "$TMP_LOCAL")"; printf '%s\n' "$contenu" > "$t"
    if remplacer_fichier "$t" "$CROCHET_APT"; then
        ok "Crochet APT installé : le thème sera réappliqué après chaque mise à jour"
    else
        erreur "crochet APT non installé (${CROCHET_APT})"
    fi
    rm -f "$t"
}

copier_script_installe() {
    (( SIMULATION )) && { simule "copierait le script dans ${SCRIPT_INSTALLE}"; return 0; }
    mkdir -p "$INSTALL_DIR" && chmod 700 "$INSTALL_DIR"
    if [[ "$SCRIPT_SOURCE" != "$SCRIPT_INSTALLE" ]] && ! cmp -s "$SCRIPT_SOURCE" "$SCRIPT_INSTALLE"; then
        install -m 0700 -o root -g root "$SCRIPT_SOURCE" "$SCRIPT_INSTALLE" \
            || erreur "copie du script dans ${INSTALL_DIR} impossible"
    fi
    if [[ -n "$OPT_MESSAGE" && "$OPT_MESSAGE" != "$MESSAGE_INSTALLE" ]]; then
        install -m 0600 -o root -g root "$OPT_MESSAGE" "$MESSAGE_INSTALLE" \
            || erreur "copie du message dans ${INSTALL_DIR} impossible"
        OPT_MESSAGE="$MESSAGE_INSTALLE"
    elif [[ -z "$OPT_MESSAGE" ]]; then
        rm -f "$MESSAGE_INSTALLE"
    fi
}

# Vérifie, depuis le serveur lui-même, que pveproxy sert bien le thème
controle_http() {
    command -v curl >/dev/null 2>&1 || { info "curl absent : contrôle HTTP non fait."; return 0; }
    local page code
    page="$(curl -sk --max-time 8 https://localhost:8006/ 2>/dev/null)"
    code="$(curl -sk --max-time 8 -o /dev/null -w '%{http_code}' "https://localhost:8006${URL_CSS}" 2>/dev/null)"
    if [[ "$page" == *"$MARQUE"* && "$code" == "200" ]]; then
        ok "Contrôle : https://localhost:8006 sert la page avec le thème (feuille : HTTP ${code})"
    else
        attention "Contrôle HTTP non concluant (page : $([[ "$page" == *"$MARQUE"* ]] && echo 'thème présent' || echo 'thème absent'), feuille : HTTP ${code:-?})."
        detail "Si pveproxy n'écoute pas sur localhost, ouvrez simplement l'interface dans le navigateur."
    fi
}

installer_local() {
    local badge_resolu css_tmp js_tmp tpl_tmp v_css="" v_js="" lignes rc

    if (( NETTOYER_ANCIEN )); then nettoyer_ancien_local; fi
    etape "Préparation [${NOEUD}]"
    if (( OPT_SANS_MESSAGE )); then OPT_MESSAGE=""; fi
    preparer_message

    badge_resolu="${OPT_BADGE//%NODE%/$NOEUD}"
    badge_resolu="${badge_resolu//%NOEUD%/$NOEUD}"
    if [[ ${#badge_resolu} -gt 48 ]]; then
        attention "Badge long (${#badge_resolu} caractères) : il risque d'être coupé dans la barre du haut."
    fi
    info "Badge : « ${badge_resolu} »"

    css_tmp="${TMP_LOCAL}/theme.css"; js_tmp="${TMP_LOCAL}/theme.js"; tpl_tmp="${TMP_LOCAL}/index.html.tpl"

    # 1) Feuille de style du thème
    etape "Feuille de style du thème [${NOEUD}]"
    generer_css "$badge_resolu" > "$css_tmp" || { erreur "génération du CSS impossible"; return 1; }
    v_css="$(sha256sum < "$css_tmp" | cut -c1-12)"
    if [[ -f "$THEME_CSS" ]] && cmp -s "$css_tmp" "$THEME_CSS"; then
        ok "Feuille du thème déjà à jour (${THEME_CSS})"
    elif (( SIMULATION )); then
        simule "écrirait ${THEME_CSS} ($(( $(stat -c %s "$css_tmp") / 1024 )) Ko, police Orbitron intégrée)"
    elif remplacer_fichier "$css_tmp" "$THEME_CSS"; then
        ok "Feuille du thème écrite : ${THEME_CSS} ($(( $(stat -c %s "$THEME_CSS") / 1024 )) Ko)"
    else
        erreur "écriture de ${THEME_CSS} impossible"; return 1
    fi

    # 2) Options pédagogiques (JavaScript séparé, seulement si une option est choisie)
    etape "Options pédagogiques [${NOEUD}]"
    if [[ -n "$OPT_MESSAGE" || "$OPT_CLONE" -eq 1 ]]; then
        generer_js > "$js_tmp" || { erreur "génération du JavaScript impossible"; return 1; }
        v_js="$(sha256sum < "$js_tmp" | cut -c1-12)"
        [[ -n "$OPT_MESSAGE" ]] && ok "Message d'accueil : activé (« ${OPT_TITRE_MESSAGE} »)"
        (( OPT_CLONE )) && ok "Clone intégral imposé aux comptes non administrateurs : activé"
        if [[ -f "$THEME_JS" ]] && cmp -s "$js_tmp" "$THEME_JS"; then
            ok "Script des options déjà à jour"
        elif (( SIMULATION )); then
            simule "écrirait ${THEME_JS}"
        elif ! remplacer_fichier "$js_tmp" "$THEME_JS"; then
            erreur "écriture de ${THEME_JS} impossible"; return 1
        fi
    else
        info "Aucune option pédagogique (message d'accueil, clone intégral) : désactivées par défaut."
        if [[ -f "$THEME_JS" ]]; then
            if (( SIMULATION )); then simule "supprimerait ${THEME_JS}"; else rm -f "$THEME_JS"; fi
        fi
    fi

    # 3) Une ou deux lignes dans index.html.tpl (idempotent : jamais de doublon)
    etape "Activation dans index.html.tpl [${NOEUD}]"
    lignes="$(lignes_template "$v_css" "$v_js")"$'\n'
    construire_template "$INDEX_TPL" "$tpl_tmp" "$lignes"; rc=$?
    [[ $rc -eq 0 ]] || { erreur "balise </head> introuvable dans ${INDEX_TPL} : rien n'est modifié."; return 1; }
    # Garde-fou : hors de nos lignes, le fichier doit rester strictement identique
    if [[ "$(grep -vF "$MARQUE" "$tpl_tmp" | md5_flux)" != "$(grep -vF "$MARQUE" "$INDEX_TPL" | md5_flux)" ]]; then
        erreur "contrôle d'intégrité du modèle échoué : rien n'est modifié."; return 1
    fi
    if cmp -s "$tpl_tmp" "$INDEX_TPL"; then
        ok "index.html.tpl déjà à jour ($(grep -cF "$MARQUE" "$INDEX_TPL") ligne(s) du thème)"
    elif (( SIMULATION )); then
        simule "modifierait ${INDEX_TPL} :"
        diff -u "$INDEX_TPL" "$tpl_tmp" | grep -E '^[+-][^+-]' | sed 's/^/        /'
    else
        sauvegarder "$INDEX_TPL" || return 1
        if remplacer_fichier "$tpl_tmp" "$INDEX_TPL"; then
            ok "index.html.tpl : $(grep -cF "$MARQUE" "$INDEX_TPL") ligne(s) du thème avant </head>"
            journal "index.html.tpl mis à jour (css v=${v_css}${v_js:+, js v=${v_js}})"
        else
            erreur "écriture de ${INDEX_TPL} impossible"; return 1
        fi
    fi

    # 4) Fenêtre d'abonnement
    etape "Fenêtre « No valid subscription » [${NOEUD}]"
    appliquer_abonnement "$OPT_SANS_ABO"
    if (( ! OPT_SANS_ABO )) && [[ "$(etat_abonnement)" == "present" ]]; then
        info "Fenêtre d'abonnement conservée (option --sans-abonnement pour la retirer)."
    fi

    # 5) Copie du script, réglages et crochet APT (survie aux mises à jour)
    etape "Mises à jour de Proxmox [${NOEUD}]"
    copier_script_installe
    ecrire_conf
    installer_crochet_apt

    if (( ! SIMULATION )) && (( ! SILENCE )); then
        etape "Vérification [${NOEUD}]"
        controle_http
    fi
    journal "installation/mise à jour ${VERSION_COURTE} terminée (erreurs : ${NB_ERREURS})"
    return 0
}


###################################################################
#     SECTION 11 : RÉAPPLICATION APRÈS MISE À JOUR (crochet APT)  #
###################################################################

reappliquer_local() {
    # Appelé par APT après chaque dpkg : rapide, silencieux, ne fait jamais échouer apt.
    [[ -f "$CONF" && -f "$INDEX_TPL" ]] || return 0
    lire_conf
    fusionner_options
    case "$PVE_MAJEUR" in
        8|9) ;;
        *) if (( ! FORCER )); then
               journal "Proxmox ${PVE_VERSION} non pris en charge : thème NON réappliqué (interface d'origine)"
               return 0
           fi ;;
    esac
    local avant_tpl avant_abo
    avant_tpl="$(grep -F "$MARQUE" "$INDEX_TPL" 2>/dev/null | md5_flux)"
    avant_abo="$(etat_abonnement)"
    ACTION="reappliquer"
    installer_local >/dev/null 2>&1 || true
    if [[ "$(grep -F "$MARQUE" "$INDEX_TPL" 2>/dev/null | md5_flux)" != "$avant_tpl" || "$(etat_abonnement)" != "$avant_abo" ]]; then
        echo "Thème Proxmox cyberpunk : réappliqué après la mise à jour (${NOEUD}, PVE ${PVE_VERSION})."
        journal "réappliqué après mise à jour de Proxmox ${PVE_VERSION}"
    fi
    return 0
}


###################################################################
#      SECTION 12 : NETTOYAGE D'UNE ANCIENNE VERSION (V27...)     #
###################################################################

# Retire ce qu'une ancienne version a AJOUTÉ à la fin d'un fichier du paquet,
# seulement si le début restant est EXACTEMENT le fichier d'origine (md5 dpkg).
nettoyer_fichier_ancien() {   # $1 = fichier, $2 = signature (regex) de l'ancien ajout
    local f="$1" signature="$2" attendu longueur taille t
    [[ -f "$f" ]] || return 0
    if [[ "$(etat_paquet "$f")" == "origine" ]]; then
        ok "$(basename "$f") : déjà identique au fichier d'origine du paquet"
        return 0
    fi
    attendu="$(md5_paquet "$f")"
    [[ -n "$attendu" ]] || { attention "$(basename "$f") : md5 d'origine introuvable (dpkg) — non touché."; return 0; }
    longueur="$(longueur_origine "$f" "$attendu")" || longueur=""
    if [[ -z "$longueur" ]]; then
        attention "$(basename "$f") : le fichier a été modifié AILLEURS qu'à la fin — non touché."
        detail "Pour repartir du fichier d'origine : apt-get install --reinstall $(dpkg -S "$f" 2>/dev/null | cut -d: -f1)"
        return 0
    fi
    taille="$(stat -c %s "$f")"
    if ! tail -c "+$((longueur + 1))" "$f" | grep -E "$signature" >/dev/null; then
        attention "$(basename "$f") : l'ajout en fin de fichier ne ressemble pas à l'ancien thème — non touché."
        return 0
    fi
    if (( SIMULATION )); then
        simule "$(basename "$f") : retirerait $((taille - longueur)) octets ajoutés (le reste = fichier d'origine, md5 vérifié)"
        return 0
    fi
    sauvegarder "$f" || return 1
    t="$(mktemp -p "$TMP_LOCAL")"
    head -c "$longueur" "$f" > "$t"
    if [[ "$(md5_flux < "$t")" == "$attendu" ]] && remplacer_fichier "$t" "$f"; then
        ok "$(basename "$f") : ancienne version retirée ($((taille - longueur)) octets), fichier d'origine retrouvé (md5 vérifié)"
        journal "ancienne version retirée de $(basename "$f")"
    else
        erreur "$(basename "$f") : nettoyage impossible"
    fi
    rm -f "$t"
}

nettoyer_ancien_local() {
    etape "Nettoyage d'une ancienne version du thème [${NOEUD}]"
    if [[ -f "$ANCIEN_CSS" ]] && grep -qE "$SIGNATURE_ANCIEN_CSS" "$ANCIEN_CSS"; then
        nettoyer_fichier_ancien "$ANCIEN_CSS" "$SIGNATURE_ANCIEN_CSS"
    else
        ok "ext6-pve.css : aucune ancienne version du thème"
    fi
    if [[ -f "$ANCIEN_JS" ]] && grep -qE "$SIGNATURE_ANCIEN_JS" "$ANCIEN_JS"; then
        nettoyer_fichier_ancien "$ANCIEN_JS" "$SIGNATURE_ANCIEN_JS"
    else
        ok "pvemanagerlib.js : aucun ancien message ajouté"
    fi
    local vieux
    vieux="$(find "$CSS_DIR" "$JS_DIR" "$(dirname "$TOOLKIT_JS")" -maxdepth 1 -type f \
        \( -name '*.backup-*' -o -name '*.pre-sub-*' -o -name '*.js.bak' \) 2>/dev/null | wc -l)"
    if [[ "$vieux" -gt 0 ]]; then
        info "${vieux} ancienne(s) copie(s) de sauvegarde (*.backup-*, *.pre-sub-*) restent dans les dossiers servis par pveproxy."
        detail "Elles ne gênent pas le thème ; à supprimer à la main si vous n'en avez plus besoin."
    fi
}


###################################################################
#                  SECTION 13 : DÉSINSTALLATION                   #
###################################################################

desinstaller_local() {
    local t etat_tpl
    etape "Désinstallation du thème [${NOEUD}]"

    # 1) index.html.tpl : on retire nos lignes, rien d'autre
    if grep -qF "$MARQUE" "$INDEX_TPL"; then
        if (( SIMULATION )); then
            simule "retirerait $(grep -cF "$MARQUE" "$INDEX_TPL") ligne(s) de ${INDEX_TPL}"
        else
            sauvegarder "$INDEX_TPL" || return 1
            t="$(mktemp -p "$TMP_LOCAL")"
            grep -vF "$MARQUE" "$INDEX_TPL" > "$t"
            if remplacer_fichier "$t" "$INDEX_TPL"; then ok "Lignes du thème retirées de index.html.tpl"
            else erreur "écriture de ${INDEX_TPL} impossible"; fi
            rm -f "$t"
        fi
    else
        ok "index.html.tpl : aucune ligne du thème"
    fi
    etat_tpl="$(etat_paquet "$INDEX_TPL")"
    if (( ! SIMULATION )); then
        case "$etat_tpl" in
            origine) ok "index.html.tpl identique au fichier d'origine du paquet (md5 vérifié)" ;;
            modifie) attention "index.html.tpl diffère encore du paquet : modification qui ne vient pas de ce script, laissée en place." ;;
            *)       info "index.html.tpl : md5 d'origine inconnu, vérification impossible." ;;
        esac
    fi

    # 2) Fenêtre d'abonnement : rétablie seulement si c'est CE script qui l'avait retirée
    appliquer_abonnement 0

    # 3) Fichiers créés par le thème
    local f
    for f in "$THEME_CSS" "$THEME_JS" "$CROCHET_APT"; do
        [[ -e "$f" ]] || continue
        if (( SIMULATION )); then simule "supprimerait ${f}"; else rm -f "$f" && ok "Supprimé : ${f}"; fi
    done
    if [[ -d "$INSTALL_DIR" ]]; then
        if (( SIMULATION )); then simule "supprimerait ${INSTALL_DIR}/ (copie du script, réglages)"
        else rm -rf "${INSTALL_DIR:?}" && ok "Supprimé : ${INSTALL_DIR}/"; fi
    fi
    journal "désinstallation terminée (erreurs : ${NB_ERREURS})"
    [[ -d "$SAUVEGARDES" ]] && info "Les sauvegardes restent dans ${SAUVEGARDES}/ (à supprimer quand vous voulez)."
    return 0
}


###################################################################
#                       SECTION 14 : ÉTAT                         #
###################################################################

afficher_etat() {
    local n abo
    etape "État du thème sur ${NOEUD}"
    printf '   Nœud        : %s (%s)\n' "$NOEUD" "$( (( EST_CLUSTER )) && echo cluster || echo 'nœud seul')"
    printf '   Proxmox VE  : %s — Debian %s %s\n' "$PVE_VERSION" "$DEBIAN_VERSION" "$DEBIAN_NOM"
    n="$(grep -cF "$MARQUE" "$INDEX_TPL" 2>/dev/null || true)"
    if [[ "${n:-0}" -gt 0 && -f "$THEME_CSS" ]]; then
        printf '   Thème       : %sINSTALLÉ%s (%s, %s)\n' "$C_VERT" "$C_RAZ" "${CONF_VERSION:-?}" "${CONF_DATE:-date inconnue}"
    elif [[ "${n:-0}" -gt 0 || -f "$THEME_CSS" ]]; then
        printf '   Thème       : %sINCOMPLET%s (relancer l’installation ou la désinstallation)\n' "$C_JAUNE" "$C_RAZ"
    else
        printf '   Thème       : non installé\n'
    fi
    if (( CONF_PRESENTE )); then
        printf '   Badge       : %s\n' "$CONF_BADGE"
        printf '   Message     : %s\n' "$( [[ "$CONF_MESSAGE" == 1 ]] && echo "oui (${CONF_TITRE_MESSAGE})" || echo non)"
        printf '   Clone int.  : %s\n' "$( [[ "$CONF_CLONE" == 1 ]] && echo oui || echo non)"
    fi
    abo="$(etat_abonnement)"
    case "$abo" in
        neutralise) abo="neutralisée$( [[ "$CONF_ABO_PAR_SCRIPT" == 1 ]] && echo ' (par ce script)' || echo ' (par autre chose que ce script)')" ;;
        present)    abo="affichée (comportement d'origine)" ;;
        *)          abo="motif introuvable" ;;
    esac
    printf '   Abonnement  : fenêtre %s\n' "$abo"
    printf '   Crochet APT : %s\n' "$( [[ -f "$CROCHET_APT" ]] && echo "présent (${CROCHET_APT})" || echo absent)"
    echo "   Fichiers de Proxmox comparés au paquet (md5 dpkg) :"
    local f e
    for f in "$INDEX_TPL" "$ANCIEN_CSS" "$ANCIEN_JS" "$TOOLKIT_JS"; do
        e="$(etat_paquet "$f")"
        if [[ "$f" == "$INDEX_TPL" && "$e" == "modifie" ]] && template_sans_nos_lignes_origine; then
            e="modifié UNIQUEMENT par le thème"
        fi
        case "$e" in origine) e="${C_VERT}identique au paquet${C_RAZ}" ;; modifie) e="${C_JAUNE}modifié${C_RAZ}" ;; esac
        printf '     %-18s %s\n' "$(basename "$f")" "$e"
    done
    detecter_anciennes_versions
    if (( EST_CLUSTER )); then
        lister_noeuds_distants
        info "Cluster : autres nœuds = ${NOEUDS_DISTANTS[*]:-aucun} (le thème s'installe sur CHAQUE nœud : option --cluster)"
    fi
}


###################################################################
#                SECTION 15 : MODE INTERACTIF (menu)              #
###################################################################

menu_principal() {
    local choix
    while true; do
        echo
        printf '   %s1)%s Installer ou mettre à jour le thème\n' "$C_GRAS" "$C_RAZ"
        printf '   %s2)%s Désinstaller (retour à l’interface d’origine)\n' "$C_GRAS" "$C_RAZ"
        printf '   %s3)%s Afficher l’état\n' "$C_GRAS" "$C_RAZ"
        printf '   %s4)%s Simulation de l’installation (ne modifie rien)\n' "$C_GRAS" "$C_RAZ"
        if (( ANCIEN_CSS_PRESENT || ANCIEN_JS_PRESENT )); then
            printf '   %s5)%s Retirer l’ancienne version du thème (V27 et antérieures)\n' "$C_GRAS" "$C_RAZ"
        fi
        printf '   %s0)%s Quitter\n\n' "$C_GRAS" "$C_RAZ"
        read -rp "   Votre choix : " choix || exit 0
        case "$choix" in
            1) ACTION="installer"; return 0 ;;
            2) ACTION="desinstaller"; return 0 ;;
            3) afficher_etat ;;
            4) ACTION="installer"; SIMULATION=1; return 0 ;;
            5) if (( ANCIEN_CSS_PRESENT || ANCIEN_JS_PRESENT )); then ACTION="nettoyer"; return 0; fi ;;
            0|q|Q) echo; exit 0 ;;
            *) echo "   Choix inconnu." ;;
        esac
    done
}

questions_installation() {
    local rep
    echo
    echo "   ${C_GRAS}Texte du badge${C_RAZ} (barre du haut). %NODE% = nom du nœud."
    echo "   Exemples : « %NODE% - Lycée Exemple », « BTS SIO - Salle B12 »"
    read -rp "   Badge [${OPT_BADGE}] : " rep || rep=""
    [[ -n "$rep" ]] && OPT_BADGE="$rep"
    echo
    if question_oui_non "Retirer la fenêtre « No valid subscription » à la connexion ?" "$( (( OPT_SANS_ABO )) && echo o || echo n)"; then
        OPT_SANS_ABO=1; else OPT_SANS_ABO=0; fi
    echo
    echo "   ${C_GRAS}Options pédagogiques${C_RAZ} (désactivées par défaut) :"
    echo "   • message d'accueil : une fenêtre affichée après la connexion (consignes, règles…)"
    if question_oui_non "Afficher un message d'accueil ?" "$([[ -n "$OPT_MESSAGE" ]] && echo o || echo n)"; then
        while true; do
            read -rp "   Fichier du message (.html ou texte) [${OPT_MESSAGE:-aucun}] : " rep || rep=""
            rep="${rep:-$OPT_MESSAGE}"
            if [[ -n "$rep" && -r "$rep" ]]; then OPT_MESSAGE="$rep"; break; fi
            echo "   Fichier introuvable. (Laisser vide puis Ctrl+C pour abandonner.)"
        done
        read -rp "   Titre de la fenêtre [${OPT_TITRE_MESSAGE}] : " rep || rep=""
        [[ -n "$rep" ]] && OPT_TITRE_MESSAGE="$rep"
    else
        OPT_MESSAGE=""
    fi
    echo "   • clone intégral : un compte NON administrateur qui clone un modèle n'a plus"
    echo "     le choix « Clone lié » (qui échoue s'il n'a pas le droit d'écrire sur le"
    echo "     stockage du modèle). Les administrateurs gardent les deux choix."
    if question_oui_non "Imposer le clone intégral aux non-administrateurs ?" "$( (( OPT_CLONE )) && echo o || echo n)"; then
        OPT_CLONE=1; else OPT_CLONE=0; fi
    if (( ANCIEN_CSS_PRESENT || ANCIEN_JS_PRESENT )); then
        echo
        if question_oui_non "Retirer l'ancienne version du thème détectée (contrôle md5) ?" "o"; then NETTOYER_ANCIEN=1; fi
    fi
    if (( EST_CLUSTER )); then
        lister_noeuds_distants
        if [[ ${#NOEUDS_DISTANTS[@]} -gt 0 ]]; then
            echo
            echo "   Ce nœud fait partie d'un cluster. Autres nœuds : ${NOEUDS_DISTANTS[*]}"
            echo "   L'interface est servie par CHAQUE nœud : le thème doit être posé sur chacun."
            if question_oui_non "Installer aussi sur ces ${#NOEUDS_DISTANTS[@]} nœud(s) (SSH root) ?" "o"; then CLUSTER=1; fi
        fi
    fi
}

recapitulatif() {
    etape "Récapitulatif"
    printf '   Nœud            : %s — Proxmox VE %s\n' "$NOEUD" "$PVE_VERSION"
    printf '   Badge           : %s\n' "$OPT_BADGE"
    printf '   Abonnement      : %s\n' "$( (( OPT_SANS_ABO )) && echo 'fenêtre retirée' || echo 'fenêtre conservée')"
    printf '   Message accueil : %s\n' "$([[ -n "$OPT_MESSAGE" ]] && echo "oui — ${OPT_MESSAGE}" || echo non)"
    printf '   Clone intégral  : %s\n' "$( (( OPT_CLONE )) && echo oui || echo non)"
    printf '   Ancienne version: %s\n' "$( (( NETTOYER_ANCIEN )) && echo 'retirée' || echo 'non traitée')"
    printf '   Autres nœuds    : %s\n' "$( (( CLUSTER )) && echo "${NOEUDS_DISTANTS[*]:-aucun}" || echo non)"
    printf '   Mode            : %s\n' "$( (( SIMULATION )) && echo 'SIMULATION (rien ne sera modifié)' || echo 'réel')"
}


###################################################################
#                SECTION 16 : POINT D'ENTRÉE                      #
###################################################################

arguments_distants() {   # options à transmettre aux autres nœuds
    local -a a=()
    case "$ACTION" in
        installer)
            a+=(--installer --badge "$OPT_BADGE")
            if (( OPT_SANS_ABO )); then a+=(--sans-abonnement); else a+=(--avec-abonnement); fi
            if (( OPT_CLONE )); then a+=(--clone-integral); else a+=(--sans-clone-integral); fi
            if [[ -n "$OPT_MESSAGE" ]]; then a+=(--titre-message "$OPT_TITRE_MESSAGE"); else a+=(--sans-message); fi
            (( NETTOYER_ANCIEN )) && a+=(--nettoyer-ancien) ;;
        desinstaller) a+=(--desinstaller) ;;
        nettoyer)     a+=(--nettoyer-ancien) ;;
    esac
    (( SIMULATION )) && a+=(--simulation)
    (( FORCER )) && a+=(--forcer)
    printf '%s\0' "${a[@]}"
}

prendre_verrou() {
    (( SIMULATION )) && return 0
    { exec 9>"$VERROU"; } 2>/dev/null || return 0
    if ! flock -n 9; then
        (( SILENCE )) && exit 0
        fatal "une autre exécution du script est en cours (${VERROU})."
    fi
}

main() {
    analyser_arguments "$@"
    TMP_LOCAL="$(mktemp -d)"
    trap 'rm -rf "$TMP_LOCAL"' EXIT

    # Mode crochet APT : silencieux, ne bloque jamais apt
    if [[ "$ACTION" == "reappliquer" ]]; then
        [[ "$(id -u)" -eq 0 ]] || exit 0
        command -v pveversion >/dev/null 2>&1 || exit 0
        prendre_verrou
        detecter_proxmox 2>/dev/null || exit 0
        reappliquer_local
        exit 0
    fi

    (( MODE_AUTO )) || [[ -n "$ACTION" ]] || { [[ -t 0 ]] || { usage; exit 1; }; }
    [[ -t 1 && -z "$ACTION" ]] && clear
    bandeau
    etape "Vérifications"
    verifier_root
    detecter_proxmox
    ok "Nœud Proxmox : ${NOEUD} ($( (( EST_CLUSTER )) && echo 'membre d’un cluster' || echo 'nœud seul'))"
    lire_conf
    fusionner_options

    if [[ -z "$ACTION" ]]; then
        verifier_version 0
        detecter_anciennes_versions
        (( CONF_PRESENTE )) && info "Thème déjà installé ici (${CONF_VERSION}, ${CONF_DATE}) : l'installation le mettra à jour."
        menu_principal
    fi

    case "$ACTION" in
        installer)
            verifier_version 1
            verifier_fichiers "$OPT_SANS_ABO"
            (( MODE_AUTO )) && detecter_anciennes_versions
            if (( ! MODE_AUTO )); then
                questions_installation
                recapitulatif
                echo
                question_oui_non "Lancer ?" "o" || { echo "   Abandon : rien n'a été modifié."; exit 0; }
            fi
            if (( SIMULATION )); then
                echo; printf '   %s>>> MODE SIMULATION : aucun fichier ne sera modifié.%s\n' "$C_JAUNE" "$C_RAZ"
            fi
            prendre_verrou
            installer_local || true ;;
        desinstaller)
            verifier_version 0
            if (( ! MODE_AUTO )) && [[ -t 0 ]]; then
                if (( EST_CLUSTER )); then
                    lister_noeuds_distants
                    if [[ ${#NOEUDS_DISTANTS[@]} -gt 0 ]] && question_oui_non "Désinstaller aussi sur ${NOEUDS_DISTANTS[*]} ?" "o"; then CLUSTER=1; fi
                fi
                question_oui_non "Désinstaller le thème de ${NOEUD}$( (( CLUSTER )) && echo ' et des autres nœuds') ?" "o" \
                    || { echo "   Abandon : rien n'a été modifié."; exit 0; }
            fi
            prendre_verrou
            desinstaller_local || true ;;
        nettoyer)
            verifier_version 0
            prendre_verrou
            nettoyer_ancien_local || true ;;
        etat)
            afficher_etat
            exit 0 ;;
    esac

    if (( CLUSTER )); then
        local -a args=()
        while IFS= read -r -d '' a; do args+=("$a"); done < <(arguments_distants)
        traiter_noeuds_distants "${args[@]}"
    fi

    echo
    printf '%s═══════════════════════════════════════════════════════════════%s\n' "$C_CYAN" "$C_RAZ"
    if (( SIMULATION )); then
        printf '   %sSIMULATION TERMINÉE : rien n’a été modifié.%s\n' "$C_GRAS" "$C_RAZ"
    elif [[ "$NB_ERREURS" -eq 0 ]]; then
        printf '   %s✔ TERMINÉ SANS ERREUR%s\n' "$C_VERT$C_GRAS" "$C_RAZ"
    else
        printf '   %s⚠ TERMINÉ AVEC %s ERREUR(S)%s — voir les messages ci-dessus et %s\n' "$C_JAUNE$C_GRAS" "$NB_ERREURS" "$C_RAZ" "$JOURNAL"
    fi
    local b
    for b in "${BILAN[@]}"; do printf '   • %s\n' "$b"; done
    if (( ! SIMULATION )); then
        case "$ACTION" in
            installer)
                echo "   • Aucun redémarrage de service : rafraîchissez la page du navigateur (Ctrl+F5)."
                echo "   • Retour à l'interface d'origine à tout moment :"
                echo "       ${SCRIPT_INSTALLE} --desinstaller"
                [[ -n "$DOSSIER_SAUVEGARDE" ]] && echo "   • Sauvegardes : ${DOSSIER_SAUVEGARDE}/" ;;
            desinstaller)
                echo "   • Interface d'origine rétablie : rafraîchissez la page du navigateur (Ctrl+F5)." ;;
        esac
    fi
    printf '%s═══════════════════════════════════════════════════════════════%s\n\n' "$C_CYAN" "$C_RAZ"
    [[ "$NB_ERREURS" -eq 0 ]] || exit 2
    exit 0
}


###################################################################
#   SECTION 17 : POLICE ORBITRON INTÉGRÉE (base64, SIL OFL 1.1)   #
#   Copyright 2018 The Orbitron Project Authors — TTF non modifiés #
###################################################################

police_orbitron_700() {
tr -d '\n' << 'FIN_B64'
AAEAAAAQAQAABAAAR0RFRgRJBGkAAAJMAAAAdkdQT1P4ncahAAAPCAAACbhHU1VCuPy46gAAAWAA
AAAoT1MvMmFczBEAAAHsAAAAYFNUQVR5k2tJAAABiAAAACpjbWFwyaNyCQAACSQAAAKmZ2FzcAAA
ABAAAAEUAAAACGdseWbdpKZ9AAAYwAAALGxoZWFkCpikxwAAAbQAAAA2aGhlYQhTAzMAAAE8AAAA
JGhtdHjvqh86AAALzAAAAzxsb2Nha3dgjAAAAsQAAAGibWF4cADcAJgAAAEcAAAAIG5hbWUxPVJC
AAAEaAAAAkpwb3N07p4E4gAABrQAAAJtcHJlcGgGjIUAAAEMAAAAB7gB/4WwBI0AAAEAAf//AA8A
AQAAANAAUwAFAEMABAABAAAAAAAAAAAAAAAAAAIAAQABAAAD8/8NAAAFX/9F/fgFGAABAAAAAAAA
AAAAAAAAAAAAzgABAAAACgAmACYAAkRGTFQAEmxhdG4ADgAAAAAABAAAAAD//wAAAAAAAQABAAgA
AQAAABQAAQAAABwAAndnaHQBAAAAAAIAAQAAAAABBAK8AAAAAAABAAAAAgBCRrNM/l8PPPUAAwPo
AAAAAMoDDTEAAAAA3R9Tk/9F/wYFGAPYAAEABgACAAAAAAAAAAQChQK8AAUAAAKKAlgAAABLAooC
WAAAAV4AMgFcAAAAAAAAAAAAAAAAgAAAZxAAAEIAAAAAAAAAAE5PTkUAoAAg4AwD8/8NAAAD8wDz
AAAAAQAAAAACRALQAAAAIAACAAEAAAAMAAAAAAAAAAIAEQABAAcAAQAKAAsAAQANABEAAQAVABkA
AQAeACUAAQAoACgAAQAqACsAAQAtADEAAQA1AEAAAQBDAEQAAQBGAEoAAQBPAFMAAQBYAF8AAQBk
AGUAAQBoAGwAAQBwAHQAAQCxALkAAwAAAAAAFgBBAE0AWQBlAHEAfQCJALgBAgElATABXQFzAX8B
iwGXAaMBtwHyAgkCFQIhAi0COQJFAmcChAKTAq4CxALQAwcDEwMfAysDNwNDA3kDpwPmBB0EagR2
BIkErQS5BMUE0QTdBPIFEAUxBUgFVAVgBXYFggWrBbcFwwXPBdsF5wXzBjMGYgaGBpEGwQb0BwAH
DAcYByQHPweAB6EHtAfBB8wH1wfiB+0ICwglCD0IZwiGCJIIygjWCOII7gj6CQYJUAmACbEJyQoX
CiMKZAqACqQKsAq8CsgK1AroCwULIgtOC1oLZgt8C4gLvwvQDA4MWwx3DLEM8A0JDWQNqA20DcQN
1w3uDgUOGA4rDl4OkQ6mDsMO8w8EDxUPNw9ZD4MPrQ++D88P3A/pD/YQAxAgEDsQTBBdEHAQfRB9
EH0QsxDkEUYRdRGJEZYRtBHOEeIR9BIIEicSlxLrEzkTahOfE6wTvxPLE9kT5xP5FAsUORRSFF8U
aBRxFHoUghSLFJQUsBS4FMEUzhTXFOMU9xUsFVoVkxWvFc8V7xYDFh0WNgAAAAAACgB+AAMAAQQJ
AAAA9gDWAAMAAQQJAAEAEADGAAMAAQQJAAIACAC+AAMAAQQJAAMAMACOAAMAAQQJAAQAGgB0AAMA
AQQJAAUAGgBaAAMAAQQJAAYAGgBAAAMAAQQJAA4ANAAMAAMAAQQJAQAADAAAAAMAAQQJAQQACAC+
AFcAZQBpAGcAaAB0AGgAdAB0AHAAOgAvAC8AcwBjAHIAaQBwAHQAcwAuAHMAaQBsAC4AbwByAGcA
LwBPAEYATABPAHIAYgBpAHQAcgBvAG4ALQBCAG8AbABkAFYAZQByAHMAaQBvAG4AIAAyAC4AMAAw
ADEATwByAGIAaQB0AHIAbwBuACAAQgBvAGwAZAAyAC4AMAAwADEAOwBOAE8ATgBFADsATwByAGIA
aQB0AHIAbwBuAC0AQgBvAGwAZABCAG8AbABkAE8AcgBiAGkAdAByAG8AbgBDAG8AcAB5AHIAaQBn
AGgAdAAgADIAMAAxADgAIABUAGgAZQAgAE8AcgBiAGkAdAByAG8AbgAgAFAAcgBvAGoAZQBjAHQA
IABBAHUAdABoAG8AcgBzACAAKABoAHQAdABwAHMAOgAvAC8AZwBpAHQAaAB1AGIALgBjAG8AbQAv
AHQAaABlAGwAZQBhAGcAdQBlAG8AZgAvAG8AcgBiAGkAdAByAG8AbgApACwAIAB3AGkAdABoACAA
UgBlAHMAZQByAHYAZQBkACAARgBvAG4AdAAgAE4AYQBtAGUAOgAgACIATwByAGIAaQB0AHIAbwBu
ACIALgAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAA0AAAACQAyQDHAGIArQBjAK4A
kAAlACYAZAAnACgAZQDIAMoAywApACoAKwAsAMwAzQDOAM8ALQAuAC8AMAAxAGYAMgDQANEAZwDT
AK8AsAAzADQANQA2AOQANwA4ANQA1QBoANYAOQA6ADsAPADrALsAPQDmAEQAaQBrAGwAagBuAG0A
oABFAEYAbwBHAEgAcAByAHMAcQBJAEoASwBMANcAdAB2AHcAdQBNAE4ATwBQAFEAeABSAHkAewB8
AHoAfQCxAFMAVABVAFYA5QCJAFcAWAB+AIAAgQB/AFkAWgBbAFwA7AC6AF0A5wATABQAFQAWABcA
GAAZABoAGwAcABEADwAdAB4AqwAEAKMAIgCiAIcADQAGABIAPwALAAwAXgBgAD4AQAAQALIAswBC
ALQAtQC2ALcABQAKAAMBAgEDAIQABwCFAA4A7wDwALgAIAAhAB8AYQAIACMACQCIAIMAXwEEAQUB
BgEHAQgBCQEKAQsBDACOANwAQwCNANgA4QDbAN0A2QDaAN4A4AENAQ4BDwEQAREBEgETARQBFQEW
B3VuaTAwQTAERXVybwd1bmkwMzA4B3VuaTAzMDcJZ3JhdmVjb21iCWFjdXRlY29tYgd1bmkwMzAy
B3VuaTAzMEMHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMyNwd1bmlFMDAyB3VuaUUwMDMHdW5pRTAw
NQd1bmlFMDA2B3VuaUUwMDcHdW5pRTAwOAd1bmlFMDA5B3VuaUUwMEEHdW5pRTAwQgd1bmlFMDBD
AAAAAAAAAgAAAAMAAAAUAAMAAQAAABQABAKSAAAATgBAAAUADgAvADkAXQB+AKMAqACwALQAtgC4
AM8A1wDdAO8A9wD9AP8BMQFTAWEBeAF+AscC3AMDAwgDCgMMAycgFCAZIB0gIiAmIKwiEuAD4Az/
/wAAACAAMAA6AF8AoACoAK8AtAC2ALgAvwDRANkA3wDxAPkA/wExAVIBYAF4AX0CxgLYAwADBwMK
AwwDJyATIBggHCAiICYgrCIS4ALgBf//AAAARQAAAAAAAAASAAAACf/4AAwAAAAAAAAAAAAAAAD/
c/8eAAAAAP6/AAD9+AAAAAAAAP2t/ar9kuCB4IHge+Bm4F3f896SIMQgwwABAE4AAABqALAA7gAA
APIAAAAAAAAA7gEOARoBIgFCAU4AAAAAAVIBVAAAAVQAAAFUAVwBYgAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAJ0AhACbAIoAoQCrAK0AnACNAI4AiQCjAIAAkwB/AIsAgQCCAKkApwCoAIYArAAB
AAkACgAMAA0AEgATABQAFQAaABsAHAAdAB4AIAAnACgAKQAqACwALQAyADMANAA1ADgAkQCMAJIA
lgC8ADoAQgBDAEUARgBLAEwATQBOAFQAVQBWAFcAWABaAGEAYgBjAGQAZwBoAG0AbgBvAHAAcwCP
ALAAkACqAJ4AhQCgAKIAwwCvAIcABQACAAMABwAEAAYACAALABEADgAPABAAGQAWABcAGAAfACQA
IQAiACUAIwClADEALgAvADAANgBmAD4AOwA8AEAAPQA/AEEARABKAEcASABJAFMAUABRAFIAWQBe
AFsAXABfAF0ApgBsAGkAagBrAHEAJgBgACsAZQA5AHQAwAC7AMEAxQDCALMAtAC1ALgAsgCxAAAB
9AAUA0QAOgNEADoDRAA6A0QAOgNEADoDRAA6A0QAOgVfADYDQAA7AzYAOAM2ADgDQgA6Av4AOgL+
ADoC/gA6Av4AOgL+ADoC0wA6Az4AOANTADkA1gAqANYAJADW/9oA1v/GANYABAMMAAQDHQA5AwsA
OQOgADgDQAA4A0AAOAM8ADYDPAA2AzwANgM8ADYDPAA2AzwANgVeADUDFwA4A3QANgM5ADgDOgA1
AzoANQL3ABQDPAA2AzwANgM8ADYDPAA2AzwANgPrACMEmwAjAywALgMmAAQDJgAEAyYABAM1ADMD
NQAzArYANAK2ADQCtgA0ArYANAK2ADQCtgA0ArYANASaADQCmwA2ArcAMwK3ADMCmwAXArQAMwK0
ADMCtAAzArQAMwK0ADMBrgA1AqsAKQKcADYA3gA0ANYAKgDWACIA1v/YANb/xADWAAIA7/9FAoYA
NgFGADQD0gA2ArgANgK4ADYCtAAzArQAMwK0ADMCtAAzArQAMwK0ADMEmQA0ApgANgKYABQCCgA0
Aq4AMAKuADADQQA5AbYANQK3ADUCtwA1ArcANQK3ADUCtwA1AxYAFQQjACMCtAAuAq0AKgKtACoC
rQAqAroANgK6ADYDQgA5AYcAAQM+ADkDOgA1AtoABgM+ADkDNAA5ApQAAwNCADkDPAA1AOMANgDj
ADYA7QA2APMAMwI+ADYA3AA6ANIANQKmAB8CowATAXMAdwH8ABkDHQAgAgkABgIIAAUBIQA0ASMA
OAEhABcBIQAzARMANgEUADMCBQA7AsQANgM2ADYDPAA2AbIALgGyADYA2gAiANgANgGFACsA8wA7
ATIAAAEyAAADHwAjAnwAIQMUACIC3gAnAcAAEQIFADsCIgA1AgQACgJ+ADsB2wA7AdkABQGUABgD
xgAwAzQANgOqADUDQQA4AbcALQDWADYAAP9ZAAD/vgAA/5cAAP+3AAD/bQAA/3IAAP+gAAD/SgAA
AVMCGABkARUASQEdADsA1QAmAe8AZAEpAAcBHwAoAOkAFQGTABQB9ABXANUAEQH0AL0DAwAuAxAA
DAMvADECmwAbAtMACQR2//8EhABGAwYANgABADYAAQAAAAoAJgBAAAJERkxUAA5sYXRuAA4ABAAA
AAD//wACAAAAAQACa2VybgAUbWFyawAOAAAAAQABAAAAAQAAAAIClAAGAAQAAAABAAgAAQJ8AeYA
AgJKAAwATwHUAc4B1AHOAdQBzgHUAc4B1AHOAdQBzgHUAc4ByAJkAcgCZAHCAbwBwgG8AcIBvAHC
AbwBwgG8AbYBsAG2AbABtgGwAbYBsAG2AbABqgGkAaoBpAGeAZgBngGYAZ4BmAGeAZgBngGYAZ4B
mAGeAZgBngGYAZ4BmAGeAZgBngGYAZ4BmAGeAZgBngGYAZIAAAGSAAABkgAAAYwAAAGMAAABhgGA
AYYBgAGGAYABhgGAAYYBgAGGAYABhgGAAYYBgAGGAYABegF0AXoBdAF6AXQBegF0AXoBdAFuAAAB
bgAAAW4AAAFuAAABbgAAAWgBYgFoAWIBXAFWAVwBVgFcAVYBXAFWAVwBVgFcAVYBUAFKAVABSgFE
AAABRAAAAUQAAAFEAAABRAAAAT4AAAE+AAABPgAAAXoAAAF6AAAAAQFQAkQAAQFcAkMAAQFcAAAA
AQFUAkQAAQFZ//4AAQFZAkIAAQFbAAAAAQFTAkQAAQBrAkQAAQFaAAAAAQFaAkQAAQFsAAAAAQFv
AkQAAQGbAtAAAQGSAtAAAQGeAAAAAQGeAtAAAQGTAAAAAQGTAtAAAQBsAAAAAQBtAtAAAQGPAAAA
AQGOAtAAAQG5AtAAAQGiAAAAAQGiAtAAAgAQAAEABwAAAAoACwAHAA0AEQAJABUAGQAOAB4AJQAT
ACgAKAAbACoAKwAcAC0AMQAeADUAQAAjAEMARAAvAEYASgAxAE8AUwA2AFgAXwA7AGQAZQBDAGgA
bABFAHAAdABKAAkAAAAsAAAALAAAACwAAAAsAAAALAAAACwAAAAsAAAALAABACYAAQG5AAAAAQAA
AkQAAgABALEAuQAAAAIACAABAAgAAQB0AAQAAAA1BtIGxAa+BqgGngaIBnoGQAa+BioGGAYOBr4F
9AXiBdgFxgWsBZoFfAVWBUgFJgUcBOIEyASWBHwERgQcA+YD1AOGA3QDagMoAv4C3AKqApgCkgJM
Ah4B6AGiAYgBTgFEARYA/AD2APAA4gABADUAAQAJAAoADAANABIAEwAVABoAGwAcAB0AHgAgACcA
KQAqACwALQAyADMANAA1ADgAOgBCAEMARQBGAEsATABNAE4AVABVAFYAVwBYAFoAYQBiAGMAZABn
AGgAbQBuAG8AcABzAIYAjQCaAAMAVgAOAGcADgBtABwAAQAsAAcAAQBtAAAABgA6/+YARv/nAE3/
+QBW/+cAZ//nAHP/5gALADr/6ABD/+kARv/pAFX/8gBW//wAWP/pAFr/6ABh//kAY//yAGT/+QBu
//kAAgBG/+EAaP/yAA4AOv/rAEP/6wBG/+AATP/eAE3/8gBO//IAVv/5AFj/7QBa/9AAY//RAGT/
1QBn//wAaP/yAHD/7wAGADr/6gBG/+IATgAHAFr/8ABk//gAbQAHABEAQv/pAEP/6QBFAAMARv/q
AEv/7ABM//kAVf/5AFf/5wBYAAIAWv/5AGH/6QBk/+sAZ//qAG7/+QBv/+4Ac//pAJr/8gANADoA
FQBCAAgARQApAE0ADwBOAAIAVwAVAGMABwBkAAcAZwAHAG0AAwBwAAcAcwAPAH8ABwALAEP/7ABG
/+0ATP/4AFX/6gBY/+gAWv/yAGj/4wBt/9wAbv/rAG//5QBz/+gAEQA6AA4AQgAHAEUAFQBGAAcA
SwAOAEwABwBNAAcATgAOAFYABwBYAA4AWgACAGQADgBoAA4AbQAHAHMABwB///oAgP9IAAEAaP/t
AAQARQAIAE4ABQBUAAcAZAADAAwAOv/qAEL/+QBW/+cAWP/nAFr/6QBj/+oAZP/qAGf/7QBo/+YA
bf/pAG7/xABv/+MACABC/+YAQ//pAEb/6wBM//kAWv/qAGH/6QBk//IAb//qAAoAOv/rAEL/6wBD
/+QARv/kAEz/4gBV/9UAV//VAFj/+QBh/9kAbv/JABAAOgAEAEIAAgBFABYARgACAEsABwBOABUA
VgAHAFf//QBYAAcAWgAEAGgACABt/+4Abv/sAHAADgBzAAcAmv/lAAIARv/+AE4ABwAEADoABwBG
//oAVAAcAGgABwATADr/9gBDAAIARQAOAEYABwBL//8ATAAAAE0ADgBVAAcAVgAVAFgAFwBhAAYA
YgAeAGMAFQBkABwAZwAOAG0ABQBuAA4AbwABAHMABwAEADoAAgBG//8ASwADAE4AAgANADr/6gBD
/+sARv/rAEv/+QBM//IAV//5AFr/6gBj/+oAZP/rAGj/5wBu/94AcP/yAHP/+QAKADoABwBFAAcA
TQAHAFQADgBWAA4AWAAOAFoABwBnABYAaAAKAID/hAANAEP/6QBG/+oATP/5AE3/+QBUAAcAVv/o
AFr/8gBj//oAZP/5AG3/0gBu/9oAb//sAHD/+QAGAEb/6gBa/+kAY//5AGj/6ABu//kAcP/yAAwA
Ff/yADr/+QBC//kAQ//5AEb/5wBN/+cAVf/mAFr/+QBj//kAZ//mAGj/5wBz/+YABgA6//kARQAJ
AGj/+QBt//gAbv/wAJoABwAOAEL/5ABD/+UATP/5AE3/+QBV//kAVv/qAFf/5gBY//UAY//sAGT/
6gBt/98Abv/ZAG//7QBz/+QAAgA1//0ARv/rAAgAKv/1ADr/1gBG/7gATv/6AFr/uABh/9QAZP+7
AGj/1gADAAn/5AA6//IARv/yAAkAAf/WACD/2gA6/9IARv++AE3/6wBO/+EAWv/LAGj/0ABw//IA
BwAB/+0AIP/2ACr/+gBG/94ATgAHAFr/1ABk/80ABABk//kAbf/yAG7/+QBv//kABgBa/8oAZP/M
AGj/4QBu/+YAcP/kAHP/4AAEAB7/5gAz/+EANf/9AG7/6wACADL/4wAz/+MABAABAAMAGv+yAEUA
AwBtAAAABgAy/98AM//fADT/3wBD//IATP/5AHP/8gACADr/+QBD/+8ABAAy/y4AM/+LADX/VwBW
AAcABQAB/+cAFP/pADr/+QBa/+sAcP/5AA4AGgAVABsABwAsAA4AOgAOAEIABwBYAA4AWgAHAGEA
DgBiAA4AYwAHAGQABwBtAB4AbgAHAG8ADgADADP/3wA1//QARQAHAAUAGv8yACkAAgAsAAoAcP/6
AH//2AACAB3/6gAg/+sABQAd//IAMv/dADP/6wA4/+UATv/5AAEARv/5AAMAMv/IADX/2gBN//kA
AgAz/9sANf/tAAIAFAAAAeAC0AAEAAkAACExJREhAzERIREB4P40Acwi/ngBAs/9UgKM/XQAAgA6
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
AAAXMTUlJTUFFTsBBP78AaQJmJeWl/J3AAEABf/5AagCVQAHAAAFMSU1JRUFBQGo/l0Bo/78AQQH
83fylpeXAAABABgA3QGEAXkAEgAAJSInJiMiBzU2MzIXFjMyNxUGIwErJDw+JCcqLSgmREMYIDI0
Jd0gIB1mEyAhHmQVAAUAMAAAA5QC0AAGABsALABBAFIAADMxNQE3FQETIiYmNTU0NjYzMzIWFhUV
FAYGIyMnMTMyNjU1NCYjIyIGFRUUFgEiJiY1NTQ2NjMzMhYWFRUUBgYjIycxMzI2NTU0JiMjIgYV
FRQWhwKjJv1fBSY8IiI8JlUmOyIiOyZVBFwJDg4JXAoNDQIVJTsiIjslViY7IiI7JlYCWwoNDQpb
Cg0NjgI/A439wgFzIzsmTCY7ISE7JkwmOyNqDQpRCg0NClEKDf4kIjsmTCY7IiI7JkwmOyJpDQpS
Cg0NClIKDQAAAgA2AAAC/wLQAC8APAAAMyImJjURNDY2MyEyFhYVESEiJiY1NTQ2NjMzMhYWFRUz
ETQmIyEiBhURFBYzIRUhEzM1NCYjIyIGFRUUFsAmPiYmPiYBtSY/Jf54JjgfHzgmSCY4HkEHBf5V
BQcHBQI6/cGjfAcFcAUICCY+JgG8Jz4lJT4n/oseNyc+JjgeHjgmWAEOBQcHBf5OBQeDATNsBQcH
BWAFBwAAAgA1//kDdgLPACkANgAAMyImJjU1NDY3JjU1NDY2MyEyFhYXFSM1NCYjISIGFRUFNTMV
FxUnBgYjJSEyNjclJyIGFRUUFr8mPiYgHBYmPiUBcyE7KAaDBwX+mAUHAZ2DeIsTQCT+UAFdCxQJ
/osPBgcHJT4nwhYuChkpaSc/JB40IE0vBQcHBXbQbaNHg08gKIMGBbwGEhuUBQcAAwA4AAADDwLG
ABIAHAAhAAAhMTUjIiYmNTU0NjYzIREjNSMVATM1IyIGFRUUFiExMzUjAbDuJj4mJj4mAk2DWP6T
6ekFBwcBclhY9CY+Jr4lQCX9OvT0AXjKBwWyBQfKAAACAC0BaQGWAskAFAAkAAATIiYmNTU0NjYz
MzIWFhUVFAYGIyMnMzI2NTU0JiMjIgYVFRQWuCc+JiY+J1UlPyUlPyVVD3EFBwcFcQUHBwFpJj8l
TCY/JSU/JkwlPyZxBwVmBQgIBWYFBwAAAQA2/5gAuQMwAAQAABcxETMRNoNoA5j8aAAC/1kCgACo
AwQABAAJAAATMTUzFSExNTMVJIT+sYMCgISEhIQAAAH/vgKAAEIDBAADAAADNTMVQoQCgISEAAH/
lwKAAEsDNwAEAAADMSczFzsuhi4CgLe3AAAB/7cCgABqAzcABAAAAzE3MwdJL4QtAoC3twAAAf9t
AokAlQMzAAcAAAMxNzMXIycHk2VeZXAlJAKJqqo/PwAAAf9yAoAAjQMjAAcAAAMxJzMXNzMHK2No
JSVpYQKAozk5owAAAv+gAocAYANDAA8AHwAAAyImNTU0NjMzMhYVFRQGIyczMjY1NTQmIyMiBhUV
FBYaHCoqHDUcKSkcNjYCAQECNgIBAQKHKBwzHCkpHDMcKDwBAjcCAgICNwIBAAAB/0oCkgC2A0wA
DgAAEyInJiMjNTMyFxYzMxUjXTc7OShATzM2Ni5QWQKSKyplLCxiAAEBU/9pAggADwADAAAFNzMH
AVMwhS+Xpqb//wBkAoABtAMEAAcAsQELAAD//wBJAoAAzQMEAAcAsgCLAAD//wA7AoAA7gM3AAcA
swCjAAD//wAmAoAA2QM3AAYAtG4A//8AZAKJAYsDMwAHALUA9wAA//8ABwKAASIDIwAHALYAlQAA
AAEAKAMSAQgDggAQAAATIiY1MxQWFzM2NjUzFAYjI4MqMVAEAzYCAk8xIzEDEjQ8Dw8BAQ8PPDT/
/wAVAvMA1AOvAAYAt3Vs//8AFAKSAYADTAAHALgAygAAAAEAVwJ+AZsC0AAEAAATMTUhFVcBRAJ+
UlL//wAR/2kAxgAPAAcAuf6+AAAAAQC9/wYBN//vAAQAABcxNTMVvXr66ekAAQAuAAAC9gLQAAgA
ADMxNQEhNSEVAS8BzP4zAsj9xiMCKoMj/VMAAAIADAAAAtYCzwAVACIAACE1NCYmIyEiJiY1NTQ2
NjMhMhYWFREBITU0JiMhIgYVFRQWAlMDDxH+Zyc+JiY+JwG1Jj4m/cYBtwgF/lYFBwf8Ew0DJT8m
myc+JiY+J/28AaKdBQcHBZEFBwABADEAAAL5AtAAHAAAMyImJycBNSEiBhUVIzU0NjYzITIWFhcV
ARUhFSG6MUwLAQJF/ksFB4QmPicBtSE5KAb9vAJE/cE+LYEBNCwHBTxCJj4mHzQfjv7MGYMAAAIA
GwAAAoMC0AAkACgAADc1NDY2MzMyNjU1NCYjIRUjNT4CMyEyFhYVFRQGBiMjIgYVFQc1MxW6Jj4m
sAUHBwX+qoMGJjoiAVYmPiYmPyWvBQeEhLJVJz4lBwWkBQdndyA0HyU+J68lPyYHBU+yg4MAAAEA
CQAAArYCzwAQAAAhMTUhNQEzFQEhNTMVMxUjFQHO/jsBZHv+ywEbg2VltHoBoUP+q46Og7QAAf//
AAAEPQLQABAAACExATUzATUDNTMBETMRIwMRAkD9v5ABvN+PAb2FkNwCrCT98uQBBSX98QIP/TAB
Bv76AAEARgAABIQC0AAQAAAzMREzEQEzFQMVATMVASMRA0aFAb2P3wG8kP3AkdwC0P3wAhAl/vvm
AhAk/VQBBv76AAABADYAAAL+AtAACAAAMzERMxEBMxUBNoMBuI39xwLQ/e4CEiz9XAAAAgABAAAC
yQLQAAkADQAAMzE1ATMRIzUhBwExMzUBAjmPhP7imQEHsCMCrf0wt7cBOs4AAAIANgAAAv4C0AAJ
AA0AADMxETMBFSMnIRURMTMnNo8COY2b/uOwsALQ/VMjt7cBOs4=
FIN_B64
}

police_orbitron_900() {
tr -d '\n' << 'FIN_B64'
AAEAAAAQAQAABAAAR0RFRgRJBGkAAAJMAAAAdkdQT1PxqNIJAAAPNAAACaxHU1VCuPy46gAAAWAA
AAAoT1MvMmIkzDMAAAHsAAAAYFNUQVR5lWwRAAABiAAAACpjbWFwyaNyCQAACVAAAAKmZ2FzcAAA
ABAAAAEUAAAACGdseWYMB+JGAAAY4AAAKRRoZWFkCoGkywAAAbQAAAA2aGhlYQg9AyMAAAE8AAAA
JGhtdHjw8h3NAAAL+AAAAzxsb2NhEFMGNgAAAsQAAAGibWF4cADcAJgAAAEcAAAAIG5hbWUyBV6J
AAAG2AAAAnhwb3N07p4E4gAABGgAAAJtcHJlcGgGjIUAAAEMAAAAB7gB/4WwBI0AAAEAAf//AA8A
AQAAANAAUwAFAEMABAABAAAAAAAAAAAAAAAAAAIAAQABAAAD8/8NAAAFX/9E/egFAwABAAAAAAAA
AAAAAAAAAAAAzgABAAAACgAmACYAAkRGTFQAEmxhdG4ADgAAAAAABAAAAAD//wAAAAAAAQABAAgA
AQAAABQAAQAAABwAAndnaHQBAAAAAAIAAQAAAAABBgOEAAAAAAABAAAAAgBCqMVeRl8PPPUAAwPo
AAAAAMoDDTEAAAAA3R9Tk/9E/wYFAwPcAAAABgACAAAAAAAAAAQChwOEAAUAAAKKAlgAAABLAooC
WAAAAV4AMgFcAAAAAAAAAAAAAAAAgAAAZxAAAEIAAAAAAAAAAE5PTkUAwAAg4AwD8/8NAAAD8wDz
AAAAAQAAAAACRALQAAAAIAACAAEAAAAMAAAAAAAAAAIAEQABAAcAAQAKAAsAAQANABEAAQAVABkA
AQAeACUAAQAoACgAAQAqACsAAQAtADEAAQA1AEAAAQBDAEQAAQBGAEoAAQBPAFMAAQBYAF8AAQBk
AGUAAQBoAGwAAQBwAHQAAQCxALkAAwAAAAAAFgA9AEkAVQBhAG0AeQCFALAA6wEOARkBPgFUAWAB
bAF4AYQBmAHLAeIB7gH6AgYCEgIeAjwCWQJoAoEClwKjAtIC3gLqAvYDAgMOAz0DYwOaA8gECQQV
BCgESARUBGAEbAR4BI0EqwTLBOIE7gT6BRAFHAVCBU4FWgVmBXIFfgWKBcAF6AYIBhMGOwZoBnQG
gAaMBpgGsQboBwUHGAclBzAHOwdGB1EHbQeHB50HvwfaB+YIFggiCC4IOghGCFIIjgi2COAI9gk4
CUQJewmVCbUJwQnNCdkJ5Qn5ChYKMgpYCmQKcAqGCpIKxQrWCwoLSwtnC5cLzAvjDC8Magx2DIcM
mgyxDMgM2wzuDRsNSA1dDXoNqg27DcwN6g4IDi4OVA5lDnYOgw6QDp0Oqg7HDuMO9Q8GDxkPJg8m
DyYPWA+GD9wQBxAbECgQRBBeEHIQgxCWELURJBFsEbMR4BINEhoSLRI5EkcSVRJnEnkSnxK4EsUS
zhLXEuAS6BLxEvoTFRMdEyYTMxM8E0gTXBOME7gT6xQHFCYURBRYFHEUigAAAAIAAAAAAAD/nAAy
AAAAAAAAAAAAAAAAAAAAAAAAAAAA0AAAACQAyQDHAGIArQBjAK4AkAAlACYAZAAnACgAZQDIAMoA
ywApACoAKwAsAMwAzQDOAM8ALQAuAC8AMAAxAGYAMgDQANEAZwDTAK8AsAAzADQANQA2AOQANwA4
ANQA1QBoANYAOQA6ADsAPADrALsAPQDmAEQAaQBrAGwAagBuAG0AoABFAEYAbwBHAEgAcAByAHMA
cQBJAEoASwBMANcAdAB2AHcAdQBNAE4ATwBQAFEAeABSAHkAewB8AHoAfQCxAFMAVABVAFYA5QCJ
AFcAWAB+AIAAgQB/AFkAWgBbAFwA7AC6AF0A5wATABQAFQAWABcAGAAZABoAGwAcABEADwAdAB4A
qwAEAKMAIgCiAIcADQAGABIAPwALAAwAXgBgAD4AQAAQALIAswBCALQAtQC2ALcABQAKAAMBAgED
AIQABwCFAA4A7wDwALgAIAAhAB8AYQAIACMACQCIAIMAXwEEAQUBBgEHAQgBCQEKAQsBDACOANwA
QwCNANgA4QDbAN0A2QDaAN4A4AENAQ4BDwEQAREBEgETARQBFQEWB3VuaTAwQTAERXVybwd1bmkw
MzA4B3VuaTAzMDcJZ3JhdmVjb21iCWFjdXRlY29tYgd1bmkwMzAyB3VuaTAzMEMHdW5pMDMwQQl0
aWxkZWNvbWIHdW5pMDMyNwd1bmlFMDAyB3VuaUUwMDMHdW5pRTAwNQd1bmlFMDA2B3VuaUUwMDcH
dW5pRTAwOAd1bmlFMDA5B3VuaUUwMEEHdW5pRTAwQgd1bmlFMDBDAAAAAAAADACWAAMAAQQJAAAA
9gDsAAMAAQQJAAEAHADQAAMAAQQJAAIADgDCAAMAAQQJAAMAMgCQAAMAAQQJAAQAHADQAAMAAQQJ
AAUAGgB2AAMAAQQJAAYAHABaAAMAAQQJAA4ANAAmAAMAAQQJABAAEAAWAAMAAQQJABEACgAMAAMA
AQQJAQAADAAAAAMAAQQJAQYACgAMAFcAZQBpAGcAaAB0AEIAbABhAGMAawBPAHIAYgBpAHQAcgBv
AG4AaAB0AHQAcAA6AC8ALwBzAGMAcgBpAHAAdABzAC4AcwBpAGwALgBvAHIAZwAvAE8ARgBMAE8A
cgBiAGkAdAByAG8AbgAtAEIAbABhAGMAawBWAGUAcgBzAGkAbwBuACAAMgAuADAAMAAxADIALgAw
ADAAMQA7AE4ATwBOAEUAOwBPAHIAYgBpAHQAcgBvAG4ALQBCAGwAYQBjAGsAUgBlAGcAdQBsAGEA
cgBPAHIAYgBpAHQAcgBvAG4AIABCAGwAYQBjAGsAQwBvAHAAeQByAGkAZwBoAHQAIAAyADAAMQA4
ACAAVABoAGUAIABPAHIAYgBpAHQAcgBvAG4AIABQAHIAbwBqAGUAYwB0ACAAQQB1AHQAaABvAHIA
cwAgACgAaAB0AHQAcABzADoALwAvAGcAaQB0AGgAdQBiAC4AYwBvAG0ALwB0AGgAZQBsAGUAYQBn
AHUAZQBvAGYALwBvAHIAYgBpAHQAcgBvAG4AKQAsACAAdwBpAHQAaAAgAFIAZQBzAGUAcgB2AGUA
ZAAgAEYAbwBuAHQAIABOAGEAbQBlADoAIAAiAE8AcgBiAGkAdAByAG8AbgAiAC4AAAACAAAAAwAA
ABQAAwABAAAAFAAEApIAAABOAEAABQAOAC8AOQBdAH4AowCoALAAtAC2ALgAzwDXAN0A7wD3AP0A
/wExAVMBYQF4AX4CxwLcAwMDCAMKAwwDJyAUIBkgHSAiICYgrCIS4APgDP//AAAAIAAwADoAXwCg
AKgArwC0ALYAuAC/ANEA2QDfAPEA+QD/ATEBUgFgAXgBfQLGAtgDAAMHAwoDDAMnIBMgGCAcICIg
JiCsIhLgAuAF//8AAABFAAAAAAAAABIAAAAJ//gADAAAAAAAAAAAAAAAAP9z/x4AAAAA/r8AAP34
AAAAAAAA/a39qv2S4IHggeB74GbgXd/z3pIgxCDDAAEATgAAAGoAsADuAAAA8gAAAAAAAADuAQ4B
GgEiAUIBTgAAAAABUgFUAAABVAAAAVQBXAFiAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAnQCE
AJsAigChAKsArQCcAI0AjgCJAKMAgACTAH8AiwCBAIIAqQCnAKgAhgCsAAEACQAKAAwADQASABMA
FAAVABoAGwAcAB0AHgAgACcAKAApACoALAAtADIAMwA0ADUAOACRAIwAkgCWALwAOgBCAEMARQBG
AEsATABNAE4AVABVAFYAVwBYAFoAYQBiAGMAZABnAGgAbQBuAG8AcABzAI8AsACQAKoAngCFAKAA
ogDDAK8AhwAFAAIAAwAHAAQABgAIAAsAEQAOAA8AEAAZABYAFwAYAB8AJAAhACIAJQAjAKUAMQAu
AC8AMAA2AGYAPgA7ADwAQAA9AD8AQQBEAEoARwBIAEkAUwBQAFEAUgBZAF4AWwBcAF8AXQCmAGwA
aQBqAGsAcQAmAGAAKwBlADkAdADAALsAwQDFAMIAswC0ALUAuACyALEAAAH0ABQDRAA6A0QAOgNE
ADoDRAA6A0QAOgNEADoDRAA6BV8ANgNAADsDNgA4AzYAOANCADoC/gA6Av4AOgL+ADoC/gA6Av4A
OgLTADoDPgA4A1MAOQDWAB8A1gAZANb/zgDW/7YA1v/0AwwABAMdADkDCwA5A6AAOANAADgDQAA4
AzwANgM8ADYDPAA2AzwANgM8ADYDPAA2BV4ANQMXADgDdAA2AzkAOAM8ADYDPAA2AvcAFAM8ADYD
PAA2AzwANgM8ADYDPAA2A+sAIwSbACMDLAAuAyb/9wMm//cDJv/3AzUAMwM1ADMCtgA0ArYANAK2
ADQCtgA0ArYANAK2ADQCtgA0BJoANAKbADYCtwAzArcAMwKbABcCtAAzArQAMwK0ADMCtAAzArQA
MwG4ADUCqwApApwANgDlADQA1gAfANYAFwDW/8wA1v+0ANb/8gDv/0UChgA2AVEANAPSADYCuAA2
ArgANgK0ADMCtAAzArQAMwK0ADMCtAAzArQAMwSZADQCmAA2ApgAFAIOADQCrgAwAq4AMANBADkB
wwA1ArcANQK3ADUCtwA1ArcANQK3ADUDFgAVBB0AIwK0AC4CrQAqAq0AKgKtACoCugA2AroANgNC
ADkBhwABAz4AOQM6ADUC2gAGAz4AOQM0ADkClAADA0IAOQM8ADMA6QA2APMANgD3ADYBCgAzAj4A
NgDcADoA0gA1AqYAHwKjABMBcwBsAgQAGQMdACACCQAGAggABQEmADQBKQA4ASEAFwEhADMBEwA2
ARQAMwIFADsCxAA2AzYANgM8ADYB0gAtAdIANgDwACIA7gA2AYwAJAD7ADsBQgAAAUIAAAMfACMC
fAAhAxQAIgLeACcBxwARAgUAOwIiADUCBwAHAn4AOwHbADsB2QAFAZQAGAPGADADLwA2A6oANQNB
ADgBtwAtANYANgAA/0kAAP+zAAD/hwAA/6wAAP9hAAD/YAAA/5oAAP9EAAABRwI3AGQBKgBIARAA
JwDVABwCCABkASn/9QEfACgA6QAPAZMADgH0AFcA1QAEAfQAvQMDAC4DEAAMAy8AMQKbABsC0wAJ
BGv//wR9AFADBgA2AAAANgABAAAACgAmAEAAAkRGTFQADmxhdG4ADgAEAAAAAP//AAIAAAABAAJr
ZXJuABRtYXJrAA4AAAABAAEAAAABAAAAAgKIAAYABAAAAAEACAABAnAB2gACAj4ADABPAcgBwgHI
AcIByAHCAcgBwgHIAcIByAHCAcgBwgG8AlgBvAJYAbYBsAG2AbABtgGwAbYBsAG2AbABqgNsAaoD
bAGqA2wBqgNsAaoDbAGkAZ4BpAGeAZgBkgGYAZIBmAGSAZgBkgGYAZIBmAGSAZgBkgGYAZIBmAGS
AZgBkgGYAZIBmAGSAZgBkgGYAZIBjAAAAYwAAAGMAAABhgAAAYYAAAGAAXoBgAF6AYABegGAAXoB
gAF6AYABegGAAXoBgAF6AYABegF0AW4BdAFuAXQBbgF0AW4BdAFuAWgAAAFoAAABaAAAAWgAAAFo
AAABYgFcAWIBXAFWAVABVgFQAVYBUAFWAVABVgFQAVYBUAFKAW4BSgFuAUQAAAFEAAABRAAAAUQA
AAFEAAABYgAAAWIAAAFiAAABPgAAAT4AAAABAVwCRAABAVsCQwABAVQCRAABAVn//gABAVkCQgAB
AVwAAAABAVACRAABAGsCRAABAVkAAAABAVkCRAABAWwAAAABAW8CRAABAZsC0AABAZIC0AABAZ4A
AAABAZ4C0AABAZMAAAABAZMC0AABAG0C0AABAY4AAAABAY4C0AABAbkC0AABAaIAAAABAaIC0AAC
ABAAAQAHAAAACgALAAcADQARAAkAFQAZAA4AHgAlABMAKAAoABsAKgArABwALQAxAB4ANQBAACMA
QwBEAC8ARgBKADEATwBTADYAWABfADsAZABlAEMAaABsAEUAcAB0AEoACQAAACwAAAAsAAAALAAA
ACwAAAAsAAAALAAAACwAAAAsAAEAJgABAbkAAAABAAACRAACAAEAsQC5AAAAAgAIAAEACAABAHQA
BAAAADUG0gbEBr4GqAaeBogGegZABr4GKgYYBg4GvgX0BeIF2AXGBawFmgV8BVYFSAUmBRwE4gTI
BJYEfARGBBwD5gPUA4YDdANqAygC/gLcAqoCmAKSAkwCHgHoAaIBiAFOAUQBFgD8APYA8ADiAAEA
NQABAAkACgAMAA0AEgATABUAGgAbABwAHQAeACAAJwApACoALAAtADIAMwA0ADUAOAA6AEIAQwBF
AEYASwBMAE0ATgBUAFUAVgBXAFgAWgBhAGIAYwBkAGcAaABtAG4AbwBwAHMAhgCNAJoAAwBWABQA
ZwAUAG0AKAABACwACgABAG0AAAAGADr/5QBG/+cATf/2AFb/5QBn/+UAc//jAAsAOv/nAEP/5wBG
/+cAVf/sAFb/9gBY/+UAWv/nAGH/9gBj/+wAZP/2AG7/9gACAEb/6QBo/+wADgA6/+IAQ//iAEb/
4ABM/88ATf/sAE7/7ABW//YAWP/lAFr/xABj/8UAZP/JAGf/+gBo/+wAcP/nAAYAOv/gAEb/4gBO
AAoAWv/2AGQAAABtAAoAEQBC/+UAQ//nAEUAAABG/+cAS//nAEz/9gBV//YAV//lAFgAAABa//YA
Yf/lAGT/6QBn/+cAbv/2AG//7QBz/+UAmv/sAA0AOgAeAEIACgBFADIATQAUAE4AAABXAB4AYwAK
AGQACgBnAAoAbQAFAHAACgBzABQAfwAKAAsAQ//rAEb/6wBM//UAVf/nAFj/5wBa/+wAaP/fAG3/
1QBu/+IAb//pAHP/5wARADoAFABCAAoARQAfAEYACgBLABQATAAKAE0ACgBOABQAVgAKAFgAFABa
AAUAZAAUAGgAFABtAAoAcwAKAH8AAACA/2MAAQBo/+8ABABFAAAATgAAAFQACgBkAAAADAA6/+UA
Qv/2AFb/5QBY/+MAWv/nAGP/5QBk/+kAZ//vAGj/5QBt/+UAbv+5AG//5QAIAEL/4wBD/+cARv/i
AEz/9gBa/+cAYf/jAGT/7ABv/+sACgA6/+EAQv/iAEP/2ABG/9gATP/VAFX/xwBX/8cAWP/2AGH/
xwBu/7sAEAA6AAsAQgADAEUAHgBGAAoASwAKAE4AHgBWAAoAVwAAAFgACgBaAAoAaAALAG0AAABu
AAAAcAAUAHMACgCaAAAAAgBGAAAATgAKAAQAOgAKAEYAAABUACgAaAAKABMAOgABAEMACgBFABQA
RgAKAEsAFABMAAAATQAUAFUACgBWAB4AWAAoAGEAFABiADIAYwAeAGQAKABnABQAbQAKAG4AFABv
ABQAcwAKAAQAOgAAAEb//wBLAAAATgAAAA0AOv/nAEP/6QBG/+kAS//2AEz/7ABX//YAWv/pAGP/
5wBk/+sAaP/nAG7/1wBw/+wAc//2AAoAOgAKAEUACgBNAAoAVAAUAFYAFABYABQAWgAKAGcAHgBo
AAoAgP+dAA0AQ//nAEb/5wBM//YATf/2AFQACgBW/+YAWv/sAGP/+QBk//YAbf/HAG7/1wBv/+sA
cP/2AAYARv/pAFr/6QBj//YAaP/nAG7/9gBw/+wADAAV/+wAOv/2AEL/9gBD//YARv/nAE3/4wBV
/+MAWv/2AGP/9gBn/+UAaP/lAHP/4wAGADr/9gBFAAAAaP/2AG3/9QBu/+kAmgAKAA4AQv/jAEP/
3QBM//YATf/2AFX/9gBW/+UAV//jAFj/9wBj/+UAZP/pAG3/2QBu/9UAb//rAHP/4wACADUAAABG
/+IACAAqAAAAOv/vAEb/zQBOAAAAWv/NAGH/7QBk/9EAaP/vAAMACf/nADr/7ABG/+wACQAB/88A
IP/TADr/xABG/7AATf/iAE7/2ABa/78AaP/EAHD/6wAHAAH/9QAgAAAAKgAAAEb/zgBOAAoAWv/O
AGT/yAAEAGT/9gBt/+wAbv/2AG//9gAGAFr/6QBk/+sAaAAAAG4AAABwAAAAcwAAAAQAHv/jADP/
3wA1AAAAbv/iAAIAMv/fADP/3wAEAAEAAAAa/+MARQAAAG0AAAAGADL/3QAz/90ANP/hAEP/7ABM
//YAc//sAAIAOv/2AEP/7AAEADL/NwAz/5EANf9bAFYACgAFAAH/6QAU/+sAOv/2AFr/4gBw//YA
DgAaAB4AGwAKACwAFAA6ABQAQgAKAFgAFABaAAoAYQAUAGIAFABjAAoAZAAKAG0ALABuAAoAbwAU
AAMAM//dADX/7wBFAAoABQAa/0IAKQAAACwACgBwAAAAfwAAAAIAHf/tACD/7wAFAB3/7AAy/9sA
M//iADj/5QBO//YAAQBG//YAAwAy/8UANf/XAE3/9gACADP/2QA1/+sAAgAUAAAB4ALQAAQACQAA
ITElESEDMREhEQHg/jQBzCj+hAECz/1YAoD9gAACADoAAAMKAtAAEAAbAAAzETQ2NjMhMhYWFREj
NSEVIxMhNTAwMSEwMDEVOihEKAGnKUMpnf5om5sBmP5oAjwpQygoQyn9xOjoAYSwsP//ADoAAAMK
A9cCJgABAAAABwC0AaIAjP//ADoAAAMKA8QCJgABAAAABwC1AaIAjP//ADoAAAMKA6YCJgABAAAA
BwCxAaIAjP//ADoAAAMKA9cCJgABAAAABwCzAaIAjP//ADoAAAMKA9UCJgABAAAABwC3AaIAjP//
ADoAAAMKA9wCJgABAAAABwC4AaIAjAACADYAAAUDAtAAFAAfAAAzMRE0NjYzIRUhFSEVIRUhFSE1
IRURMSE1MDAxITAwMTYpQygEOf4DAZn+ZwH9/Wj+aAGY/mgCPClDKJx+nH6c6OgBhLAAAAMAOwAA
AwsC0AATACMAMwAAMxEhMhYWFRUUBgcWFhUVFAYGIyE3ITAwMTUwMDEhMDAxFTAwESEwMDE1MDAx
ITAwMRUwMDsCIChDKQMEDxQpQyn9xZsBmP5oAXz+hALQKEMphw0XChMyGZUoRCichIQBIHh4AAAB
ADgAAAMGAtAAFQAAMyImJjURNDY2MyEVISIGFREUFjMhFcwpQygoQykCOv3uEBEREAISKEMpAagp
QyicEBH+qhARnAD//wA4/2QDBgLQAiYACgAAAAYAuQAAAAIAOgAAAwoC0AALABsAADMRITIWFhUR
FAYGIyUhMDAxETAwMSEwMDERMDA6AjspQykpQyn+XwGZ/mcC0ChDKf5YKEQonAGY/mgAAQA6AAAC
0wLQAAsAADMRIRUhFSEVIRUhFToCmf4EAZn+ZwH8AtCcfpx+nP//ADoAAALTA9cCJgANAAAABwC0
AY4AjP//ADoAAALTA8QCJgANAAAABwC1AY4AjP//ADoAAALTA6YCJgANAAAABwCxAY4AjP//ADoA
AALTA9cCJgANAAAABwCzAY4AjAABADoAAALTAtAACQAAMxEhFSEVIRUhEToCmf4EAZn+ZwLQnH6c
/uYAAQA4AAADCALQACkAADMiJiY1ETQ2NjMhMhYWFRUjNTAwMSEwMDERMDAxITAwMTUjNSERFAYG
I8woRCgoRCgBpylDKZ3+aAGYnAE5KUMpKEQoAagpQygoQylEPP5obJz+8ChEKAAAAQA5AAADGALQ
AAsAADMRMxEhETMRIxEhETmbAambm/5XAtD+5gEa/TABGv7mAAEAHwAAALgC0AADAAAzETMRH5kC
0P0w//8AGQAAAOkD1wImABUAAAAHALQAbQCM////zgAAAQ4DxAImABUAAAAHALUAbQCM////tgAA
ASUDpgImABUAAAAHALEAbQCM////9AAAAMQD1wImABUAAAAHALMAbQCMAAEABAAAAtQC0AAVAAAz
IiYmNTUzFTAwMSEwMDERMxEUBgYjmChEKJsBmJ0pQygoRChdVQI0/cQoRCgAAAEAOQAAAvAC0AAO
AAAzETMRMxMzFQEBFSMDIxE5nI3sov7/AQGi7I0C0P7mARo2/s7+zjYBGv7mAAABADkAAAMJAtEA
BQAAMxEzESEVOZsCNQLR/cucAAABADgAAANgAtAACwAAMxEzExMzESMRAwMROKD086Gc+PkC0P7d
ASP9MAHj/tgBJ/4eAAEAOAAAAwgC0AAJAAAzETMBETMRIwEROKABk52g/msC0P4gAeD9MAHi/h7/
/wA4AAADCAPcAiYAHgAAAAcAuAGTAIwAAgA2AAADBgLQABMAIwAAMyImJjURNDY2MyEyFhYVERQG
BiMlITAwMREwMDEhMDAxETAwyihEKChEKAGoKEMpKUMo/l8BmP5oKEQoAagpQygoQyn+WChEKJwB
mP5o//8ANgAAAwYD1wImACAAAAAHALQBngCM//8ANgAAAwYDxAImACAAAAAHALUBngCM//8ANgAA
AwYDpgImACAAAAAHALEBngCM//8ANgAAAwYD1wImACAAAAAHALMBngCM//8ANgAAAwYD3AImACAA
AAAHALgBngCMAAIANQAABQIC0AATACMAADMiJiY1ETQ2NjMhFSEVIRUhFSEVJSEwMDERMDAxITAw
MREwMMkoRCgoRCgEOf4DAZn+ZwH9+9ABmP5oKEQoAagpQyicfpx+nJwBmP5oAAACADgAAAMIAs8A
DQAdAAAzESEyFhYVFRQGBiMFFREhMDAxNTAwMSEwMDEVMDA4AjspQykpQyn+YAGY/mgCzyhEKLoo
RCgB7AGJq6sAAwA2AAADWALQAAUAGQApAAAhNTcxMxUhIiYmNRE0NjYzITIWFhURFAYGIyUhMDAx
ETAwMSEwMDERMDACbJpS/XIoRCgoRCgBqChDKSlDKP5fAZj+aJAMnChEKAGoKUMoKEMp/lgoRCic
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
NTM1MxUzFSMVk4KCmYaGVoWZg4OZhQABADsA2wHcAXQABAAANzE1IRU7AaHbmZkAAAEANQBSAfsC
BAAQAAA3MTU3JzUzFzczFQcXFSMnBzWBgZ5ERZ+Cgp9FRVIyqKYyXl4ypqgyXV0AAwAHAAAB8QJo
AAQACQAOAAA3MTUhFQUxNTMVAzE1MxUHAer+xpmZmfCZmfCZmQHOmpoAAAIAOwCBAkkB5AAEAAkA
ABMxNSEVBTE1IRU7Ag798gIOAUuZmcqZmQABADv/7QHnAl0ABwAAFzE1Nyc1BRU76ekBrBOyh4ax
94EAAQAF/+8BsAJfAAcAAAUxJTUlFQcXAbD+VQGr6uoR+ID4sIeIAAABABgA0gGPAYMAEgAAJSIn
JiMiBzU2MzIXFjMyNxUGIwEsJDo7IiYzNSomQUEYIDg8J9IfHieEFx8fJH4ZAAUAMAAAA40CzwAG
ABsALABBAFIAADMxNQEzFQEDIiYmNTU0NjYzMzIWFhUVFAYGIyM3MTMyNjU1NCYjIyIGFRUUFgEi
JiY1NTQ2NjMzMhYWFRUUBgYjIzcxMzI2NTU0JiMjIgYVFRQWhgKQM/1wASg9IyM9KFEoPSMjPShR
FiQOExMOJA4TEwH0Jz0jIz0nUSg9IyM9KFEXJA4TEw4kDhMTnQIynP3NAXEjPShIKD0iIj0oSCg9
I34TDhoOExMOGg4T/hojPShIKD0iIj0oSCg9I30TDhsOExMOGw4TAAIANgAAAvkC0AAvADwAADMi
JiY1ETQ2NjMhMhYWFREhIiYmNTU0NjYzMzIWFhUVMzUwMDEhMDAxETAwMSEVIRMzNTAwMSMwMDEV
MDDIKEIoKEIoAZ8oQij+gCg4Hh44KD4oOB0s/m8CKv3PnWVlKEInAa4oQicnQij+mR04KDUoOB0d
OCg/7P5imQFLUlIAAAIANf/uA2oCzwApADYAADMiJiY1NTQ2NyY1NTQ2NjMhMhYWFxUjNTAwMSEw
MDEVBTUzFRcVJwYGIyUhMjIzJSciFBUVMDDGJ0IoFhUHKEInAWEjPioGmf6vAWyZc4wVQCP+aAEg
CxMK/skPAidBKbkWMA4RJGspQiYfNiJYNWy3X6FEnlAcIpmdCBAfdgADADgAAAMPAsIAEgAcACEA
ACExNSMiJiY1NTQ2NjMhESM1IxUBMzUjMDAxFTAwITEzNSMBmtAoQigoQigCRZlC/p3JyQFjQkLo
KEIntydDKP0+6OgBgqampgACAC0BVwGhAsIAFAAkAAATIiYmNTU0NjYzMzIWFhUVFAYGIyMnMzAw
MTUwMDEjMDAxFTAwvyhCKChCKFEnQigoQidRC2ZmAVcoQihIKEInJ0IoSChCKIhcXAABADb/nQDP
AyQABAAAFzERMxE2mWMDh/x5AAL/SQKAALgDGgAEAAkAABMxNTMVITE1MxUemv6RmQKAmpqamgAA
Af+zAoAATQMaAAMAAAM1MxVNmgKAmpoAAf+HAoAAVwNLAAQAAAMxJzMXRjOdMwKAy8sAAAH/rAKA
AHwDSwAEAAADMTczB1QznTMCgMvLAAAB/2ECgAChAzgABwAAAzE3MxcjJwefbmRuhhwZAoC4uCws
AAAB/2ACgACgAzgABwAAAzEnMxc3MwcyboMbG4duAoC4LCy4AAAC/5oCgABmA0kADwAfAAADIiY1
NTQ2MzMyFhUVFAYjJzMwMDE1MDAxIzAwMRUwMBkfLi4fMx8tLR8zMjICgC0fMR8tLR8xHy1FNjYA
Af9EAogAvANQAA4AABMiJyYjIzUzMhcWMzMVI1Y5NjQiTVk3Ly8tXWYCiCoqdCsrcgABAUf/ZAIY
AA8AAwAABTczBwFHNJ00nKur//8AZAKAAdMDGgAHALEBGwAA//8ASAKAAOIDGgAHALIAlQAA//8A
JwKAAPcDSwAHALMAoAAA//8AHAKAAOwDSwAGALRwAP//AGQCgAGkAzgABwC1AQMAAP////UCgAE1
AzgABwC2AJUAAAABACgC6wEaA3AAEAAAEyImNTcUFBUzNDQ1MxQGIyOPMDdmJ2U4JS4C6zpKAQ4P
AQEPDks6AP//AA8C7ADbA7UABgC3dWz//wAOAogBhgNQAAcAuADKAAAAAQBXAn4BmwLQAAQAABMx
NSEVVwFEAn5SUv//AAT/ZADVAA8ABwC5/r0AAAABAL3/BgE3/+8ABAAAFzE1MxW9evrp6QABAC4A
AALxAtAACAAAMzE1ASE1IRUBLgGm/loCw/3ZMwIEmTL9YgAAAgAMAAACzwLPABUAIgAAITU0NgYj
ISImJjU1NDY2MyEyFhYVEQEhNTAwMSEwMDEVMDACNgENFf6JKEIoKEIoAaAoQif91wGQ/nD3FgwB
J0IolChCKChCKP3DAbGEhAAAAQAxAAAC8wLPABwAADMiJicnATUhMDAxFSM1NDY2MyEyFhYXFQEV
IRUhwTNQDAECKP5ymihCKAGgJD0pBv3YAij9zkEwhgErFEVNKEInHzYik/7VAZkAAAIAGwAAAoEC
0AAkACgAADc1NDY2MzMwMDE1MDAxIRUjNT4CMyEyFhYVFRQGBiMjMDAxFQc1MxWyKEInpf7MmQUo
PiQBRidCKChCJ6Samr5SKEInlmKCIjcgJ0IopihCKEm+mZkAAAEACQAAArECzgAQAAAhMTUhNQEz
FQEzNTMVMxUjFQG4/lEBWor+7N+ZYGCxhwGWU/7Qh4easQAAAf//AAAELALQABAAACExATUzATUn
NTMBETMRIycVAjD9z6ABlNefAZWcn74CnDT+IK3+Nf4eAeL9MOHhAAABAFAAAAR9AtAAEAAAMzER
MxEBMxUHFQEzFQEjNQdQnAGUoNcBk6H9z5+9AtD+HQHjNf6wAeM0/WTh4QABADYAAAL5AtAACAAA
MzERMxEBMxUBNpkBjpz92gLQ/hoB5kD9cAAAAgAAAAACwgLQAAkADQAAMTE1ATMRIzUjBwExMzUC
JZ2a+pIBEnoyAp79MK6uAUeQAAACADYAAAL5AtAACQANAAAzMREzARUjJyMVETEzJzadAiadk/p6
egLQ/WIyrq4BR5AA
FIN_B64
}

main "$@"
