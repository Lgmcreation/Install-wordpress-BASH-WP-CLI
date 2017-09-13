#!//bin/sh
#
# Automatize WordPress installation
# bash install.sh
#
# https://github.com/posykrat/dfwp_tools/blob/master/install.sh
# http://www.wp-spread.com/tuto-wp-cli-comment-installer-et-configurer-wordpress-en-moins-dune-minute-et-en-seulement-un-clic/

#  ==============================
#  ECHO COLORS, FUNCTIONS AND VARS
#  ==============================
bggreen='\033[42m'
bgred='\033[41m'
bold='\033[1m'
black='\033[30m'
gray='\033[37m'
normal='\033[0m'
# Jump a line
function line {
	echo " "
}

# Basic echo
function bot {
	line
	echo -e "$1 ${normal}"
}

# Error echo
function error {
	line
	echo -e "${bgred}${bold}${gray} $1 ${normal}"
}

# Success echo
function success {
	line
	echo -e "${bggreen}${bold}${gray} $1 ${normal}"
}

#  ==============================
#  VARS
#  ==============================

# Path courant du  script
#path=`pwd` #Repertoire courant du  script
rootpath="/Applications/MAMP/htdocs/"
# Admin Email
adminemail="contact@lgmcreation.fr"
#Clef ACF
acfkey="votre cle ACF PRO"
#ID admin et editor (idamin générer par RANDOM)
idadmin=$[ ( $RANDOM % 500 )  + 100 ]
ideditor=`expr $idadmin + 1`


#  ==============================
#  DEBUT SCRIPT 
#  ==============================


# On récupère le nom du dossier
# Si pas de valeur renseignée ou dossier déjà existant, message d'erreur et exit
read -p "Nom du dossier ? " foldername
while [ -z $foldername ] || [ -d "${rootpath}${foldername}/" ]
	do
		error 'Renseigner un nom de dossier / Dossier déjà existant'
		read -p "Nom du dossier ? " foldername
	done


# On récupère le titre du site
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Titre du projet ? " title
while [ -z "$title" ]
	do
		error 'Renseigner un titre pour le site'
		read -p "Titre du projet ? " title
	done

# On récupère le login admin
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Administrateur ? " adminlogin
while [ -z "$adminlogin" ]
	do
		error 'Nom administrateur'
		read -p "Administrateur ? " adminlogin
	done

# On récupère le pass admin
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Mot de passe ? " adminpass
while [ -z "$adminpass" ]
	do
		error 'Pass administrateur'
		read -p "Mot de passe ? " adminpass
	done

# On récupère le titre du site
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Prefix table ? " prefix
while [ -z "$prefix" ]
	do
		error 'Prefix table'
		read -p "Prefix table ? " prefix
	done

# Savoir si on veut créer artciles
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Création d'articles (o/n) ? " articles
while [[ x$articles != xo && x$articles != xn ]]
do
        error 'Taper o (oui) ou n (non)'
        read -p "Création d'articles (o/n) ? " articles
done


# On récupère la future URL du site pour changer le htaccess
read -p "URL du futur site (sans http://www.) ? " urlsite

# VARS

pathtoinstall="${rootpath}${foldername}/"
url="http://lgm.dev/$foldername/"
dbname=$foldername
dbuser=root
dbpass=root
dbprefix=$prefix"_"


success "Récap"
echo "--------------------------------------"
echo -e "Url : $url"
echo -e "Foldername : $foldername"
echo -e "Titre du projet : $title"
echo "--------------------------------------"


# Welcome !
success "L'installation va pouvoir commencer"
echo "--------------------------------------"

# Je crée le dosssier dans mamp
bot "Je crée le dossier : $foldername"
cd $rootpath
mkdir $foldername
cd $foldername

bot "Je crée le fichier de configuration wp-cli.yml"
echo "
# Configuration de wpcli
# Voir http://wp-cli.org/config/
# Les modules apaches à charger
apache_modules:
	- mod_rewrite
" >> wp-cli.yml


# Télécharge WP
bot "Je télécharge la dernière version de WordPress en français..."
wp core download --locale=fr_FR --force

# Check version
bot "J'ai récupéré cette version :"
wp core version

# Create base configuration
bot "Je lance la configuration"
wp core config --dbname=$dbname --dbuser=$dbuser --dbpass=$dbpass --dbprefix=$dbprefix --extra-php <<PHP
// Désactiver l'éditeur de thème et de plugins en administration
define('DISALLOW_FILE_EDIT', true);

// Changer le nombre de révisions de contenus
define('WP_POST_REVISIONS', 3);

// Supprimer automatiquement la corbeille tous les 7 jours
define('EMPTY_TRASH_DAYS', 7);

// sauvegarde auto 5 min
define('AUTOSAVE_INTERVAL', 300 ); // seconds

//Mode debug
define('WP_DEBUG', true);
PHP

# Creation base de donnée
bot "Je crée la base de données"
wp db create

#Installation wordpress
bot "J'installe WordPress..."
wp core install --url=$url --title="$title" --admin_user="$adminlogin" --admin_email="$adminemail" --admin_password="$adminpass"


# Télécharge mon thème Wordpress par default
bot "Je télécharge mon thème de base"
cd wp-content/themes/
git clone https://github.com/Lgmcreation/Wordpress-Starter-Theme.git

# Modifie le nom du theme
bot "Je modifie le nom du theme"
mv Wordpress-Starter-Theme $foldername

#supprime le dossier caché git installé
cd $foldername
rm -rf .git
rm -f README.md

sed -i.bak "s/nouveausite/${title}/g" style.css
rm -f style.css.bak

#modifie mon fichier gulpfile.js (adresse dans browserSync) (pourquoi ? .bak bug ios donc supprimme le fichier .bak créé )
sed -i.bak "s/nouveausite/${foldername}/g" gulpfile.js
rm -f gulpfile.js.bak

# Modifie le fichier style.sccss (bak bug macos)
cd dev/css/
sed -i.bak "s/nouveausite/${title}/g" style.scss
rm -f style.scss.bak

# Activate theme
bot "J'active le thème $foldername:"
wp theme activate $foldername

# Plugins install
bot "J'installe les plugins"
wp plugin install wordpress-seo --activate
wp plugin install wps-hide-login 
wp plugin install simple-page-ordering --activate
wp plugin install block-bad-queries --activate

# Si on a bien une clé acf pro
if [ -n "$acfkey" ]
then
	bot "J'installe ACF PRO"
	cd $foldername/wp-content/plugins/
	curl -L -v 'http://connect.advancedcustomfields.com/index.php?p=pro&a=download&k='$acfkey > advanced-custom-fields-pro.zip
	wp plugin install advanced-custom-fields-pro.zip --activate
	rm -f advanced-custom-fields-pro.zip

	bot "J'installe WPCLI POUR ACF PRO"
	cd $rootpath
	cd $foldername/wp-content/plugins/
	git clone https://github.com/hoppinger/advanced-custom-fields-wpcli.git
	wp plugin activate advanced-custom-fields-wpcli
fi

#supprime plugin hello.php
rm -f hello.php

# Supprime post articles terms
bot "Je supprime les posts, comments et terms"
wp site empty --yes

#Création pages Wordpress
bot "Je crée les pages standards accueil contact mentions légales"
wp post create --post_type=page --post_title='Accueil' --post_status=publish
wp post create --post_type=page --post_title='Contact' --post_status=publish
wp post create --post_type=page --post_title='Mentions Légales' --post_status=publish

#Création articles
if [ "$articles" = "o" ]; then
	bot "Je crée des articles"
    curl http://loripsum.net/api/5 | wp post generate --post_content --count=5
fi

bot "Je modifie les options"
#Tailles desimages
wp option update thumbnail_size_w 320
wp option update thumbnail_size_h 320
wp option update medium_size_w 640
wp option update medium_size_h 640

# Définition page accueil
bot "Je change la page d'accueil"
wp option update show_on_front page
wp option update page_on_front 1

# Supprime les thèmes et plugins et arcticles
bot "Je supprime les thèmes de base"
wp theme delete twentyseventeen
wp theme delete twentysixteen
wp theme delete twentyfifteen
wp option update blogdescription ''

# Active Permalien
bot "J'active la structure des permaliens"
wp rewrite structure "/%postname%/" --hard
wp rewrite flush --hard

# Crée le Menu 
bot "Je crée le menu principal, assigne les pages, et je lie l'emplacement du thème : "
wp menu create "Menu Principal"
wp menu item add-post menu-principal 1
wp menu item add-post menu-principal 2
wp menu location assign menu-principal main-menu

# Change l'ID ADMIN et auto incremente l'ID 
bot "Je modifie l'ID de l'ADMIN"
wp db query "
UPDATE ${prefix}_users SET ID = ${idadmin} WHERE ID = 1;
UPDATE ${prefix}_usermeta SET user_id=${idadmin} WHERE user_id=1;
UPDATE ${prefix}_posts SET post_author=${idadmin} WHERE post_author=0;
ALTER TABLE ${prefix}_users AUTO_INCREMENT = ${ideditor};
"

#dossier ou se trouve dans le starter thele les fichiers .htacces / robots.txt et json acf
maj_theme="${rootpath}${foldername}/wp-content/themes/${foldername}/installation"
# Fichiers à inclure
maj_htaccess="${maj_theme}/maj_htaccess.txt"
htaccess_includes="${maj_theme}/htaccess_dossier_includes.txt"
htaccess_content_upload="${maj_theme}/htaccess_dossier_content_upload.txt"
robots="${maj_theme}/robots.txt"
acf_reseau_json="${maj_theme}/acf_reseaux.json"
acf_entreprise_json="${maj_theme}/acf_entreprise.json"

# Modification fichier htaccess à la racine 
bot "J'ajoute des règles Apache dans le fichier htaccess"
cd $pathtoinstall
cat $maj_htaccess >> .htaccess
if [ -n "$urlsite" ]
then
    sed -i.bak "s/monsite\.com/${urlsite}/g" .htaccess
	rm -f .htaccess.bak
fi

#Ajout htaccess wp-includes
bot "J'ajoute un htaccess dans wp-include"
cp  $htaccess_includes $pathtoinstall/wp-includes/.htaccess

#Ajout htaccess wp-content
bot "J'ajoute un htaccess dans wp-content"
cp  $htaccess_includes $pathtoinstall/wp-content/.htaccess

#Ajout htaccess wp-upload
bot "J'ajoute un htaccess dans uploads"
cp  $htaccess_content_upload $pathtoinstall/wp-content/uploads/.htaccess

#Ajout robots.txt
bot "Je crée le fichier robots.txt"
cp  $robots $pathtoinstall/robots.txt


#Upload de mes fichiers json de base pour ACF option
bot "Configuration ACF option"
cd $rootpath
cd $foldername
wp acf import --json_file=$acf_reseau_json
wp acf import --json_file=$acf_entreprise_json

wp plugin delete advanced-custom-fields-wpcli

#Suppression fichiers et répertoire
bot "Je supprime fichier license et readme"
rm -f license.txt
rm -f readme.html
#Efface le fichier WPCLI
bot "Je supprime fichier wp-cli.yml"
rm -f wp-cli.yml
#Efface dossier installation
bot "Je supprime le dossier installation"
cd wp-content/themes
cd $foldername
rm -rf installation

# Fin
success "L'installation est terminée !"
echo "--------------------------------------"
echo -e "Url			: $url"
echo -e "Path			: $pathtoinstall"
echo -e "Admin login	: $adminlogin"
echo -e "Admin pass		: $adminpass"
echo -e "Admin email	: $adminemail"
echo -e "DB name 		: localhost"
echo -e "DB user 		: root"
echo -e "DB pass 		: root"
echo -e "DB prefix 		: $dbprefix"
echo -e "WP_DEBUG 		: TRUE"
echo "--------------------------------------"

# Ouvre le site sur ma page web
open $url
open "${url}wp-admin"

#ouvre fenetre terminal et lance npm install pour gulp (window 1 pour rester sur la meme fenetre ouverte)
osascript -e 'tell application "Terminal"
 do script "cd '$pathtoinstall'/wp-content/themes/'$foldername'" activate
  do script "npm install" in window 1
end tell'

