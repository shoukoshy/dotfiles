#!/bin/bash

# Note: Turn off "Transfer file" plugin of blueman to fix OBEX in bluetuith
#       Turn on Notification in xfce4-power-manager-settings (Power Manager)

# ======================================================== #
#                 Kiểm tra trước cài đặt
# ======================================================== #

# Kiểm tra có dùng sudo không
if [ "$UID" -eq 0 ]; then
    echo -e "\e[31m Do not use sudo \e[0m"
    exit
fi

# Kiểm tra xem thư mục dotfiles có tồn tại không
if [ ! -e "$HOME/dotfiles" ]; then
    echo -e "\e[31m Please clone this repo to /home/$USER/ \e[0m"
    exit
fi

# ======================================================== #


# ======================================================== #
#                      Hàm log lỗi                         
# ======================================================== #

# Log dir
LOG_FILE="$HOME/dotfiles/logs.log"

# Khởi tạo biến toàn cục
errorCount=0
errorMessages=()

# Hàm kiểm tra và ghi lỗi
function checkAndLogError {
    local status=$1
    local message=$2

    if [ "$status" -ne 0 ]; then
        errorCount=$((errorCount + 1))
        errorMessages+=("$message")
        echo -e "\e[31m [ ERROR ] $message \e[0m"
    else
        echo -e "\e[32m [ DONE ] Not $message \e[0m"
    fi
}

# ======================================================== #


# Không cần sử dụng "source ~/.bashrc" nữa
export PATH="$PATH:/usr/local/bin:/usr/local/sbin:/opt/bin:$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin"


# ======================================================== #
#                 Cài đặt các gói cần thiết
# ======================================================== #

# Pacman
echo -e "\e[32m [ INFO ] Installing pacman packages \e[0m"
sudo pacman -Syu && sudo pacman -S --needed \
    neofetch ripgrep fzf git base-devel bat redshift \
    eza feh firefox github-cli kitty brightnessctl \
    xf86-input-libinput xorg-xinput imv libnotify \
    network-manager-applet nodejs npm nemo gnome-keyring \
    polybar pulseaudio pulseaudio-bluetooth mupdf \
    python-pynvim rofi xdg-utils zoxide zsh acpi \
    noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk ttf-croscore \
    ttf-jetbrains-mono-nerd thefuck xclip rofi-emoji \
    go bottom discord qbittorrent lf pavucontrol cronie \
    xorg-server xorg-apps xorg-xinit xorg-xmessage pacman-contrib \
    libx11 libxft libxinerama libxrandr libxss whois \
    pkgconf alacritty wget curl zip unzip spotify-launcher \
    bluez bluez-utils blueman neovide playerctl obs-studio \
    gnome-themes-extra ksnip mpv dunst calcurse tree less \
    xorg-xdpyinfo xorg-xrandr xorg-xrdb xorg-xset imagemagick \
    bc xfce4-power-manager libreoffice-fresh bluez-obex p7zip conky \
    libxext xorgproto xcb-util libxcb xcb-util-renderutil \
    xcb-util-image pixman dbus libconfig pcre libev libevdev uthash
checkAndLogError $? "Failed to install pacman packages"

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
checkAndLogError $? "Failed to install Rust"
cargo install trashy
checkAndLogError $? "Failed to install trashy"

sudo npm install -g neovim
checkAndLogError $? "Failed to install neovim (npm)"

# Cài đặt yay
echo -e "\e[32m [ INFO ] Install yay \e[0m"
git clone https://aur.archlinux.org/yay.git "$HOME/yay"
cd "$HOME/yay"
makepkg -si
checkAndLogError $? "Failed to build and install yay."
cd "$HOME/dotfiles"
sudo rm -rf "$HOME/yay"

# Yay packages
echo -e "\e[32m [ INFO ] Installing yay packages \e[0m"
yay -S --needed \
    python-pynput \
    bluetuith \
    adwaita-qt5-git \
    adwaita-qt6-git \
    visual-studio-code-bin \
    rofi-greenclip \
    i3lock-color \
    betterlockscreen \
    picom-ftlabs-git \
    logiops
checkAndLogError $? "Failed to install yay packages"

# Cài đặt Oh My Zsh
echo -e "\e[32m [ INFO ] Oh-my-zsh \e[0m"
cd "$HOME"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
checkAndLogError $? "Failed to install Oh-my-zsh."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
checkAndLogError $? "Failed to clone zsh-autosuggestions."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
checkAndLogError $? "Failed to clone zsh-syntax-highlighting"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
checkAndLogError $? "Failed to clone powerlevel10k"


# ======================================================== #


# ======================================================== #
#                    Sao chép cấu hình
# ======================================================== #

# Sao chép các file cấu hình .config, ~
echo -e "\e[32m [ INFO ] Copy dotfiles and config files \e[0m"
cd "$HOME/dotfiles"
cp -rf .config "$HOME" | tee -a "$LOG_FILE"
checkAndLogError $? "Failed to copy .config files"
cp -rf home/.* "$HOME" | tee -a "$LOG_FILE"
checkAndLogError $? "Failed to copy home files."
cp -rf .local "$HOME" | tee -a "$LOG_FILE"
checkAndLogError $? "Failed to copy .local files."

# Git config
git config --global user.name "Trần Quang Mạnh"
git config --global user.email "manhtq0508@gmail.com"
git config --global init.defaultBranch main

# Cấu hình touchpad
echo -e "\e[32m [ INFO ] Config touchpad (natural scrolling, tap, etc) \e[0m"
sudo cp 30-touchpad.conf /etc/X11/xorg.conf.d/ | tee -a "$LOG_FILE"
checkAndLogError $? "Failed to configure touchpad."

echo -e "\e[32m [ INFO ] Config DPI \e[0m"
sudo cp logid.cfg /etc | tee -a "$LOG_FILE"
checkAndLogError $? "Failed to config DPI"
echo -e "\e[32m [ INFO ] Turn DPI service on \e[0m"
sudo systemctl enable logid
checkAndLogError $? "Failed to turn on DPI service"

# Cấu hình module điều chỉnh độ sáng của Polybar
echo -e "\e[32m [ INFO ] Rules for adjust brightness, power alert \e[0m"
sudo usermod -aG video "$USER" | tee -a "$LOG_FILE"
sudo cp -rf rules.d /etc/udev | tee -a "$LOG_FILE"
checkAndLogError $? "Failed to configure rules."

# Load fontconfig
echo -e "\e[32m [ INFO ] Config font \e[0m"
fc-cache -fv
checkAndLogError $? "Fail to config font"

# ======================================================== #



# ======================================================== #
#                 Cài đặt XMonad
# ======================================================== #

# Clone xmonad, xmonad-contrib
echo -e "\e[32m [ INFO ] Clone xmonad, xmonad-contrib \e[0m"
git clone https://github.com/xmonad/xmonad "$HOME/.config/xmonad/xmonad"
checkAndLogError $? "Failed to clone xmonad repository."
git clone https://github.com/xmonad/xmonad-contrib "$HOME/.config/xmonad/xmonad-contrib"
checkAndLogError $? "Failed to clone xmonad-contrib repository."

# Cài đặt GHCup và Stack để build XMonad
echo -e "\e[32m [ INFO ] Install GHCup, stack to build xmonad \e[0m"
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
checkAndLogError $? "Failed to install GHCup."

# Build XMonad
source "$HOME/.ghcup/env" # Load ghcup env
if command -v "stack" > /dev/null; then
    echo -e "\e[32m [ INFO ] Stack found. Build XMonad. \e[0m"
    cd "$HOME/.config/xmonad"
    stack init
    stack install
    checkAndLogError $? "Failed to build and install XMonad."
else
    echo -e "\e[31m Stack not found. Try using new shell. \e[0m"
    bash -c "source $HOME/.ghcup/env && cd $HOME/.config/xmonad && stack init && stack install"
    checkAndLogError $? "Failed to build and install XMonad after retry."
fi

if command -v "xmonad" > /dev/null; then
    echo -e "\e[32m XMonad installed! \e[0m"
else
    echo -e "\e[31m XMonad not installed! \e[0m"
fi

# ======================================================== #


# ======================================================== #
#                      Bluetooth
# ======================================================== #

# Turn on Bluetooth service
echo -e "\e[32m [ INFO ] Enable Bluetooth service \e[0m"
sudo modprobe btusb
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
# systemctl --user start obex
# checkAndLogError $? "Failed to enable Bluetooth obex service."
# sudo systemctl --global enable obex
# checkAndLogError $? "Failed to enable Bluetooth obex service."

# ======================================================== #


# ======================================================== #
#                     Betterlockscreen
# ======================================================== #

sudo systemctl enable betterlockscreen@manhtq
checkAndLogError $? "Failed to turn on betterlockscreen"

# ======================================================== #


# ======================================================== #
#                        Ibus-Bamboo
# ======================================================== #

# Install ibus
sudo pacman -S --needed ibus
checkAndLogError $? "Failed to install ibus."

# Config ibus
echo -e "\e[32m [ INFO ] Config ibus \e[0m"
ibus-daemon -rxRd
checkAndLogError $? "Failed to start ibus-daemon."

# Cập nhật biến môi trường
echo -e "\e[32m [ INFO ] Update environment variables \e[0m"
echo -e "GTK_IM_MODULE=ibus\nQT_IM_MODULE=ibus\nXMODIFIERS=@im=ibus" | sudo tee -a /etc/environment
checkAndLogError $? "Failed to update environment variables."

# Install ibus-bamboo
echo -e "\e[32m [ INFO ] Install ibus-bamboo \e[0m"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BambooEngine/ibus-bamboo/master/archlinux/install.sh)"

# Restart ibus
ibus restart

# ======================================================== #


# ======================================================== #
#                       Biến môi trường
# ======================================================== #

# Cập nhật biến môi trường
echo -e "\e[32m [ INFO ] Update environment variables \e[0m"
echo -e "TERMINAL=kitty\nSHELL=zsh\nEDITOR=nvim" | sudo tee -a /etc/environment
checkAndLogError $? "Failed to update environment variables."

# ======================================================== #

# In thống kê lỗi
if [ $errorCount -gt 0 ]; then
    echo -e "\e[31m [ ERROR ] There were $errorCount errors during the script execution. \e[0m" | tee -a "$LOG_FILE"
    echo "Error details:" | tee -a "$LOG_FILE"
    for msg in "${errorMessages[@]}"; do
        echo "- $msg" | tee -a "$LOG_FILE"
    done
else
    echo -e "\e[32m [ INFO ] No errors encountered. \e[0m" | tee -a "$LOG_FILE"
fi
