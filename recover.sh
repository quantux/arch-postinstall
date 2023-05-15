#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Terminal colors
LightColor='\033[1;32m'
NC='\033[0m'

# Get current regular user (not sudo user)
RUID=$(who | awk 'FNR == 1 {print $1}')
RUSER_UID=$(id -u ${RUID})

show_message() {
    clear
    printf "${LightColor}$1${NC}\n\n"
}

user_do() {
    sudo -u ${RUID} /bin/bash -c "$1"
}

# Fix clock time for windows dualboot
timedatectl set-local-rtc 1

# Recover backup files
show_message "Recuperando arquivos de backup"
gpg --decrypt assets/backups/home.tar.gz.gpg > /tmp/home.tar.gz
tar -zxvf /tmp/home.tar.gz -C /tmp
rsync -aAXv /tmp/home/ /home/$RUID/
chown -R $RUID:$RUID /home/$RUID/

# Install packages using yay
show_message "Instalando pacotes - yay"
user_do "yay -S --needed --noconfirm --sudoloop google-chrome microsoft-edge-stable-bin anydesk-bin ttf-ms-win10-auto teamviewer grub-customizer dropbox visual-studio-code-bin rar snapd kazam preload python2 jstest-gtk-git rpi-imager android-studio insomnia postman-bin"

# Install packages using pacman
show_message "Instalando pacotes - pacman"
sudo pacman -S --noconfirm --needed base-devel flatpak tmux git curl wget ca-certificates gnupg blender thunderbird vim gedit gimp flameshot plymouth ttf-fira-code cheese screenfetch python python-gnupg python-pip python-setuptools python-pylint inkscape virtualbox virtualbox-guest-iso virtualbox-guest-utils vlc filezilla steam gparted pinta nmap traceroute ncdu p7zip okular discord tlp dkms acpi_call-dkms powerline-fonts calibre samba gnome-boxes audacity htop scrcpy whois ncurses lib32-ncurses gmp remmina tree obs-studio joyutils speedtest-cli pv neovim clang intel-media-driver cmake ninja pkg-config libxcb libyaml xz ffmpeg xclip tldr plymouth openshot wine wireshark-qt wireshark-cli libdvdread apache nginx openssh php php-apache mariadb jdk-openjdk docker

# Add user to vbox group
usermod -aG vboxusers $RUID

# Update tldr
user_do "tldr --update"

# Update flatpak
show_message "Atualizando pacotes flatpak"
flatpak remote-delete --force flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update -y

# Install flatpak packages
show_message "Instalando pacotes flatpak"
flatpak install -y --noninteractive flathub com.github.calo001.fondo
flatpak install -y --noninteractive flathub com.github.tchx84.Flatseal

# Install - Adapta Nokto Fonts
show_message "Instalando fontes Roboto e Noto Sans"
wget "https://fonts.google.com/download?family=Roboto" -O /tmp/roboto.zip
wget "https://fonts.google.com/download?family=Noto Sans" -O /tmp/noto_sans.zip
unzip /tmp/roboto.zip -d /usr/share/fonts/
unzip /tmp/noto_sans.zip -d /usr/share/fonts/

# Install - Adapta Nokto theme
show_message "Instalando Adapta Nokto"
tar -xf ./assets/themes/Adapta-Nokto.tar.xz -C /usr/share/themes

# Install Sweet Theme
show_message "Instalando Sweet Theme"
tar -xf ./assets/themes/Sweet-mars-v40.tar.xz -C /usr/share/themes

# Install Sweet Theme
show_message "Instalando Flat Remix theme"
tar -xf ./assets/themes/Flat-Remix-GTK-Blue-Darkest-Solid-NoBorder.tar.xz -C /usr/share/themes

# La-capitaine Icons
show_message "Instalando ícones la-capitaine"
tar -zxvf ./assets/icons/la-capitaine.tar.gz -C /usr/share/icons/

# WPS Office Fonts
show_message "Instalando fontes para o WPS Office"
git clone https://github.com/udoyen/wps-fonts.git /tmp/wps-fonts
mv /tmp/wps-fonts/wps /usr/share/fonts/

# Install oh-my-zsh
show_message "Instalando oh-my-zsh"
user_do "sh ./assets/oh-my-zsh/oh-my-zsh-install.sh --unattended"
chsh -s $(which zsh) $(whoami)

# Install oh-my-posh
show_message "Instalando oh-my-posh"
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
chmod +x /usr/local/bin/oh-my-posh

# Load dconf file
show_message "Carregando configurações do dconf"
user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${RUSER_UID}/bus' dconf load / < ./assets/cinnamon-settings/dconf"

# Set themes and wallpaper
show_message "Aplicando Wallpaper"
user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${RUSER_UID}/bus' gsettings set org.cinnamon.desktop.background picture-uri 'file:///$PWD/assets/wallpapers/default-wallpaper.jpg'"

# Install grub themes
show_message "Instalando grub themes"
git clone https://github.com/vinceliuice/grub2-themes assets/grub2-themes
./assets/grub2-themes/install.sh -b -t tela

# Install snap bitwarden
show_message "Instalando bitwarden"
snap install bitwarden

# Allow games run in fullscreen mode
echo "SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0" >> /etc/environment

# Customize Plymouth theme
show_message "Instalando tema do plymouth"
git clone https://github.com/adi1090x/plymouth-themes /usr/share/themes/plymouth-themes
cp -r /usr/share/themes/plymouth-themes/pack_2/hexagon_alt /usr/share/plymouth/themes/
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/hexagon_alt/hexagon_alt.plymouth 100
update-alternatives --config default.plymouth
update-initramfs -u

# Install samba
show_message "Configurando Samba"
mkdir -p /home/$RUID/Kodi
mkdir -p /home/$RUID/Kodi/Movies
mkdir -p /home/$RUID/Kodi/Series
cp assets/samba/smb.conf /etc/samba/smb.conf
smbpasswd -a $RUID
setfacl -R -m "u:$RUID:rwx" /home/$RUID/Kodi/
systemctl restart smbd

# Configuring mysql
show_message "Configurando MariaDB"
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* TO `root`@`localhost` IDENTIFIED BY '' WITH GRANT OPTION; FLUSH PRIVILEGES;"

# Instalar Composer
show_message "Instalando Composer"
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
user_do "composer global require laravel/installer"

# Disable servers system startup
systemctl disable httpd.service 
systemctl disable nginx.service
systemctl disable mariadb

# Define zsh como shell padrão
show_message "Definir zsh como shell padrão"
user_do "chsh -s $(which zsh)"

# Reiniciar
show_message ""
while true; do
    read -p "Finalizado! Deseja reiniciar? (y/n): " yn
    case $yn in
        [Yy]* ) reboot; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
