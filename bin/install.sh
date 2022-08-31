#!/bin/bash
set -e
set -o pipefail

# install.sh
#	This script installs my basic setup for a debian laptop

export DEBIAN_FRONTEND=noninteractive

# Choose a user account to use for this installation
get_user() {
	if [[ -z "${TARGET_USER-}" ]]; then
		mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)
		# if there is only one option just use that user
		if [ "${#options[@]}" -eq "1" ]; then
			readonly TARGET_USER="${options[0]}"
			echo "Using user account: ${TARGET_USER}"
			return
		fi

		# iterate through the user options and print them
		PS3='command -v user account should be used? '

		select opt in "${options[@]}"; do
			readonly TARGET_USER=$opt
			break
		done
	fi
}

check_is_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root."
		exit
	fi
}

setup_sources_min() {
	apt update || true
	apt install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		dirmngr \
		gnupg2 \
		lsb-release \
		--no-install-recommends

	DISTRO=$(lsb_release -c -s)
	export DISTRO

	# hack for latest git (don't judge)
	cat <<-EOF > /etc/apt/sources.list.d/git-core.list
	deb [signed-by=/usr/share/keyrings/git-core-archive-keyring.gpg] http://ppa.launchpad.net/git-core/ppa/ubuntu $DISTRO main
	# deb-src [signed-by=/usr/share/keyrings/git-core-archive-keyring.gpg] http://ppa.launchpad.net/git-core/ppa/ubuntu $DISTRO main
	EOF

	# Add iovisor/bcc-tools distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/iovisor.list
	deb [signed-by=/usr/share/keyrings/iovisor-archive-keyring.gpg] https://repo.iovisor.org/apt/bionic bionic main
	EOF

	# Import git-core public key
	curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xe1dd270288b4e6030699e45fa1715d88e1df1f24" | gpg --dearmor > /usr/share/keyrings/git-core-archive-keyring.gpg

	# Import iovisor/bcc-tools public key
	curl -fsSL https://repo.iovisor.org/GPG-KEY | gpg --dearmor > /usr/share/keyrings/iovisor-archive-keyring.gpg

	# turn off translations, speed up apt update
	mkdir -p /etc/apt/apt.conf.d
	echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
}

# sets up apt sources
# assumes you are going to use debian buster
setup_sources() {
	setup_sources_min;

	DISTRO=$(lsb_release -c -s)
	export DISTRO

	# Add yubico distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/yubico.list
	deb [signed-by=/usr/share/keyrings/yubico-archive-keyring.gpg] http://ppa.launchpad.net/yubico/stable/ubuntu $DISTRO main
	# deb-src [signed-by=/usr/share/keyrings/yubico-archive-keyring.gpg] http://ppa.launchpad.net/yubico/stable/ubuntu $DISTRO main
	EOF

	# Create an environment variable for the correct distribution
	CLOUD_SDK_REPO="cloud-sdk-bionic"
	export CLOUD_SDK_REPO

	# Add Cloud SDK distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/google-cloud-sdk.list
	deb [signed-by=/usr/share/keyrings/google-cloud-sdk-archive-keyring.gpg] http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main
	EOF

	# Import yubico public key
	curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3653e21064b19d134466702e43d5c49532cba1a9" | gpg --dearmor > /usr/share/keyrings/yubico-archive-keyring.gpg

	# Import Google Cloud Platform public key
	curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor > /usr/share/keyrings/google-cloud-sdk-archive-keyring.gpg
}

base_min() {
	apt update || true
	apt -y upgrade

	apt install -y \
		acpi \
		adduser \
		automake \
		bash-completion \
		bc \
		bzip2 \
		ca-certificates \
		coreutils \
		curl \
		dnsutils \
		file \
		findutils \
		flameshot \
		gcc \
		git \
		gnupg \
		gnupg2 \
		grep \
		gzip \
		hostname \
		indent \
		iptables \
		jq \
		less \
		libc6-dev \
		locales \
		lsof \
		make \
		mount \
		net-tools \
		openvpn \
		policykit-1 \
		silversearcher-ag \
		ssh \
		strace \
		sudo \
		tar \
		tmux \
		tree \
		tzdata \
		unzip \
		vim \
		xclip \
		xz-utils \
		zip \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	install_scripts
}

# installs base packages
# the utter bare minimal shit
base() {
	base_min;

	apt update || true
	apt -y upgrade

	apt install -y \
		apparmor \
		bridge-utils \
		cgroupfs-mount \
		fwupd \
		fwupdate \
		gnupg-agent \
		google-cloud-sdk \
		iwd \
		libapparmor-dev \
		libimobiledevice6 \
		libltdl-dev \
		libpam-systemd \
		libseccomp-dev \
		pinentry-curses \
		scdaemon \
		systemd \
		--no-install-recommends

	setup_sudo

	apt autoremove
	apt autoclean
	apt clean
}

# sets up apt sources for applications
setup_sources_apps() {
	DISTRO=$(lsb_release -c -s)
	export DISTRO

	# Add Google Chrome distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/google-chrome.list
	deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-archive-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main
	EOF

	# Add Docker distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/docker.list
	deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
	EOF

	# Add Codium distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/vscodium.list
	deb [signed-by=/usr/share/keyrings/codium-archive-keyring.gpg] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main
	EOF

	# Add Skype distribution URI as a package sourc
	cat <<-EOF > /etc/apt/sources.list.d/skype-stable.list
	deb [arch=amd64 signed-by=/usr/share/keyrings/skype-archive-keyring.gpg] https://repo.skype.com/deb stable main
	EOF

	# Add Slack distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/slack.list
	deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main
	EOF

	# Add Spotify distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/spotify.list
	deb [signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg] http://repository.spotify.com stable non-free
	EOF

	# Add OBS Studio distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/obs-studio.list
	deb [signed-by=/usr/share/keyrings/obsproject-archive-keyring.gpg] http://ppa.launchpad.net/obsproject/obs-studio/ubuntu/ $DISTRO main
	# deb-src [signed-by=/usr/share/keyrings/obsproject-archive-keyring.gpg] http://ppa.launchpad.net/obsproject/obs-studio/ubuntu/ $DISTRO main
	EOF

	# Import the Google Chrome public key
	curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome-archive-keyring.gpg

	# Import Docker public key
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor > /usr/share/keyrings/docker-archive-keyring.gpg

	# Import Codium public key
	curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor > /usr/share/keyrings/codium-archive-keyring.gpg

	# Import Skype public key
	curl -fsSL https://repo.skype.com/data/SKYPE-GPG-KEY | gpg --dearmor > /usr/share/keyrings/skype-archive-keyring.gpg

	# Import Slack public key
	curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey | gpg --dearmor > /usr/share/keyrings/slack-archive-keyring.gpg

	# Import Spotify public key
	curl -fsSL https://download.spotify.com/debian/pubkey_0D811D58.gpg | gpg --dearmor > /usr/share/keyrings/spotify-archive-keyring.gpg

	# Import OBS Studio public key
	curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xbc7345f522079769f5bbe987efc71127f425e228" | gpg --dearmor > /usr/share/keyrings/obsproject-archive-keyring.gpg
}

# installs application packages
install_apps() {
	apt update || true
	apt -y upgrade

	apt install -y \
		codium \
		containerd.io \
		docker-ce \
		docker-ce-cli \
		ffmpeg \
		gimp \
		google-chrome-stable \
		meld \
		npm \
		obs-studio \
		parcellite \
		rhythmbox \
		shellcheck \
		spotify-client \
		telegram-desktop \
		vlc \
		--no-install-recommends

	apt install -y \
		i3xrocks-battery \
		i3xrocks-cpu-usage \
		i3xrocks-keyboard-layout \
		i3xrocks-memory \
		i3xrocks-net-traffic \
		i3xrocks-time \
		i3xrocks-volume \
		i3xrocks-weather \
		i3xrocks-wifi \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	curl -fsSL https://starship.rs/install.sh | bash -s -- --yes
}

# install and configure dropbear
install_dropbear() {
	apt update || true
	apt -y upgrade

	apt install -y \
		dropbear-initramfs \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	# change the default port and settings
	echo 'DROPBEAR_OPTIONS="-p 4748 -s -j -k -I 60"' >> /etc/dropbear-initramfs/config

	# update the authorized keys
	cp "/home/${TARGET_USER}/.ssh/authorized_keys" /etc/dropbear-initramfs/authorized_keys
	sed -i 's/ssh-/no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="\/bin\/cryptroot-unlock" ssh-/g' /etc/dropbear-initramfs/authorized_keys

	echo
	echo "Updated config in /etc/dropbear-initramfs/config:"
	cat /etc/dropbear-initramfs/config
	echo

	echo "Updated authorized_keys in /etc/dropbear-initramfs/authorized_keys:"
	cat /etc/dropbear-initramfs/authorized_keys
	echo

	echo "Dropbear has been installed and configured."
	echo
	echo "You will now want to update your initramfs:"
	printf "\\tupdate-initramfs -u\\n"
}

# setup sudo for a user
# because fuck typing that shit all the time
# just have a decent password
# and lock your computer when you aren't using it
# if they have your password they can sudo anyways
# so its pointless
# i know what the fuck im doing ;)
setup_sudo() {
	# add user to sudoers
	adduser "$TARGET_USER" sudo

	# add user to systemd groups
	# then you wont need sudo to view logs and shit
	gpasswd -a "$TARGET_USER" systemd-journal
	gpasswd -a "$TARGET_USER" systemd-network

	# create docker group
	sudo groupadd docker
	sudo gpasswd -a "$TARGET_USER" docker

	# add go path to secure path
	{ \
		echo -e "Defaults	secure_path=\"/usr/local/go/bin:/home/${TARGET_USER}/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/bcc/tools:/home/${TARGET_USER}/.cargo/bin\""; \
		echo -e 'Defaults	env_keep += "ftp_proxy http_proxy https_proxy no_proxy GOPATH EDITOR"'; \
		echo -e "${TARGET_USER} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \
	} >> /etc/sudoers

	# # setup downloads folder as tmpfs
	# # that way things are removed on reboot
	# # i like things clean but you may not want this
	# mkdir -p "/home/$TARGET_USER/Downloads"
	# echo -e "\\n# tmpfs for downloads\\ntmpfs\\t/home/${TARGET_USER}/Downloads\\ttmpfs\\tnodev,nosuid,size=5G\\t0\\t0" >> /etc/fstab
}

# install rust
install_rust() {
	curl https://sh.rustup.rs -sSf | sh
}

# install/update golang from source
install_golang() {
	export GO_VERSION
	GO_VERSION=$(curl -sSL "https://golang.org/VERSION?m=text")
	export GO_SRC=/usr/local/go

	# if we are passing the version
	if [[ -n "$1" ]]; then
		GO_VERSION=$1
	fi

	# purge old src
	if [[ -d "$GO_SRC" ]]; then
		sudo rm -rf "$GO_SRC"
	fi

	GO_VERSION=${GO_VERSION#go}

	# subshell
	(
	kernel=$(uname -s | tr '[:upper:]' '[:lower:]')
	curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.${kernel}-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
	local user="$USER"
	# rebuild stdlib for faster builds
	sudo chown -R "${user}" /usr/local/go/pkg
	CGO_ENABLED=0 go install -a -installsuffix cgo std
	)

	# get commandline tools
	(
	set -x
	set +e
	go install golang.org/x/lint/golint@latest
	go install golang.org/x/tools/cmd/cover@latest
	go install golang.org/x/tools/gopls@latest
	go install golang.org/x/review/git-codereview@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install golang.org/x/tools/cmd/gorename@latest
	go install golang.org/x/tools/cmd/guru@latest

	# go install github.com/genuinetools/amicontained@latest
	# go install github.com/genuinetools/apk-file@latest
	# go install github.com/genuinetools/audit@latest
	# go install github.com/genuinetools/bpfd@latest
	# go install github.com/genuinetools/bpfps@latest
	# go install github.com/genuinetools/certok@latest
	# go install github.com/genuinetools/netns@latest
	# go install github.com/genuinetools/pepper@latest
	# go install github.com/genuinetools/reg@latest
	# go install github.com/genuinetools/udict@latest
	go install github.com/genuinetools/weather@latest

	# go install github.com/jessfraz/gmailfilters@latest
	# go install github.com/jessfraz/junk/sembump@latest
	# go install github.com/jessfraz/secping@latest
	# go install github.com/jessfraz/ship@latest
	# go install github.com/jessfraz/tdash@latest

	go install github.com/axw/gocov/gocov@latest
	go install honnef.co/go/tools/cmd/staticcheck@latest

	# Tools for vimgo.
	go install github.com/jstemmer/gotags@latest
	go install github.com/nsf/gocode@latest
	go install github.com/rogpeppe/godef@latest

	# aliases=( genuinetools/contained.af genuinetools/binctr genuinetools/img docker/docker moby/buildkit opencontainers/runc )
	# for project in "${aliases[@]}"; do
	# 	owner=$(dirname "$project")
	# 	repo=$(basename "$project")
	# 	if [[ -d "${HOME}/${repo}" ]]; then
	# 		rm -rf "${HOME:?}/${repo}"
	# 	fi

	# 	mkdir -p "${GOPATH}/src/github.com/${owner}"

	# 	if [[ ! -d "${GOPATH}/src/github.com/${project}" ]]; then
	# 		(
	# 		# clone the repo
	# 		cd "${GOPATH}/src/github.com/${owner}"
	# 		git clone "https://github.com/${project}.git"
	# 		# fix the remote path, since our gitconfig will make it git@
	# 		cd "${GOPATH}/src/github.com/${project}"
	# 		git remote set-url origin "https://github.com/${project}.git"
	# 		)
	# 	else
	# 		echo "found ${project} already in gopath"
	# 	fi

	# 	# make sure we create the right git remotes
	# 	if [[ "$owner" != "jessfraz" ]] && [[ "$owner" != "genuinetools" ]]; then
	# 		(
	# 		cd "${GOPATH}/src/github.com/${project}"
	# 		git remote set-url --push origin no_push
	# 		git remote add jessfraz "https://github.com/jessfraz/${repo}.git"
	# 		)
	# 	fi
	# done

	# # do special things for k8s GOPATH
	# mkdir -p "${GOPATH}/src/k8s.io"
	# kubes_repos=( community kubernetes release sig-release )
	# for krepo in "${kubes_repos[@]}"; do
	# 	git clone "https://github.com/kubernetes/${krepo}.git" "${GOPATH}/src/k8s.io/${krepo}"
	# 	cd "${GOPATH}/src/k8s.io/${krepo}"
	# 	git remote set-url --push origin no_push
	# 	git remote add jessfraz "https://github.com/jessfraz/${krepo}.git"
	# done
	)

	# # symlink weather binary for motd
	# sudo ln -snf "${GOPATH}/bin/weather" /usr/local/bin/weather
}

# install graphics drivers
install_graphics() {
	local system=$1

	if [[ -z "$system" ]]; then
		echo "You need to specify whether it's intel, geforce or optimus"
		exit 1
	fi

	local pkgs=( xorg xserver-xorg xserver-xorg-input-libinput xserver-xorg-input-synaptics )

	case $system in
		"intel")
			pkgs+=( xserver-xorg-video-intel )
			;;
		"geforce")
			pkgs+=( nvidia-driver )
			;;
		"optimus")
			pkgs+=( nvidia-kernel-dkms bumblebee-nvidia primus )
			;;
		*)
			echo "You need to specify whether it's intel, geforce or optimus"
			exit 1
			;;
	esac

	apt update || true
	apt -y upgrade

	apt install -y "${pkgs[@]}" --no-install-recommends
}

# install custom scripts/binaries
install_scripts() {
	# install speedtest
	curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  > /usr/local/bin/speedtest
	chmod +x /usr/local/bin/speedtest

	# install icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/icdiff > /usr/local/bin/icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/git-icdiff > /usr/local/bin/git-icdiff
	chmod +x /usr/local/bin/icdiff
	chmod +x /usr/local/bin/git-icdiff

	# # install lolcat
	# curl -sSL https://raw.githubusercontent.com/tehmaze/lolcat/master/lolcat > /usr/local/bin/lolcat
	# chmod +x /usr/local/bin/lolcat


	# local scripts=( have light )

	# for script in "${scripts[@]}"; do
	# 	curl -sSL "https://misc.j3ss.co/binaries/$script" > "/usr/local/bin/${script}"
	# 	chmod +x "/usr/local/bin/${script}"
	# done
}

# install stuff for i3 window manager
install_wmapps() {
	apt update || true
	apt install -y \
		bluez \
		bluez-firmware \
		feh \
		i3 \
		i3lock \
		i3status \
		pulseaudio \
		pulseaudio-module-bluetooth \
		pulsemixer \
		rofi \
		rxvt-unicode-256color \
		scrot \
		usbmuxd \
		xclip \
		xcompmgr \
		--no-install-recommends

	# start and enable pulseaudio
	systemctl --user daemon-reload
	systemctl --user enable pulseaudio.service
	systemctl --user enable pulseaudio.socket
	systemctl --user start pulseaudio.service

	# update clickpad settings
	mkdir -p /etc/X11/xorg.conf.d/
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/X11/xorg.conf.d/50-synaptics-clickpad.conf > /etc/X11/xorg.conf.d/50-synaptics-clickpad.conf

	# add xorg conf
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/X11/xorg.conf > /etc/X11/xorg.conf

	# get correct sound cards on boot
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/modprobe.d/intel.conf > /etc/modprobe.d/intel.conf

	# pretty fonts
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/fonts/local.conf > /etc/fonts/local.conf

	echo "Fonts file setup successfully now run:"
	echo "	dpkg-reconfigure fontconfig-config"
	echo "with settings: "
	echo "	Autohinter, Automatic, No."
	echo "Run: "
	echo "	dpkg-reconfigure fontconfig"
}

get_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	if [[ ! -d "${HOME}/dotfiles" ]]; then
		# install dotfiles from repo
		git clone git@github.com:jessfraz/dotfiles.git "${HOME}/dotfiles"
	fi

	cd "${HOME}/dotfiles"

	# set the correct origin
	git remote set-url origin git@github.com:jessfraz/dotfiles.git

	# installs all the things
	make

	# enable dbus for the user session
	# systemctl --user enable dbus.socket

	sudo systemctl enable "i3lock@${TARGET_USER}"

	cd "$HOME"
	mkdir -p ~/Pictures/Screenshots
	)

	install_vim;
}

install_vim() {
	# create subshell
	(
	cd "$HOME"

	# install .vim files
	sudo rm -rf "${HOME}/.vim"
	git clone --recursive git@github.com:jessfraz/.vim.git "${HOME}/.vim"
	(
	cd "${HOME}/.vim"
	make install
	)

	# update alternatives to vim
	sudo update-alternatives --install /usr/bin/vi vi "$(command -v vim)" 60
	sudo update-alternatives --config vi
	sudo update-alternatives --install /usr/bin/editor editor "$(command -v vim)" 60
	sudo update-alternatives --config editor
	)
}

install_tools() {
	echo "Installing golang..."
	echo
	install_golang;

	echo
	echo "Installing rust..."
	echo
	install_rust;

	echo
	echo "Installing scripts..."
	echo
	sudo install.sh scripts;
}

usage() {
	echo -e "install.sh\\n\\tThis script installs my basic setup for a debian laptop\\n"
	echo "Usage:"
	echo "  base                                - setup sources & install base pkgs"
	echo "  basemin                             - setup sources & install base min pkgs"
	echo "  apps                                - setup sources & install applications"
	echo "  graphics {intel, geforce, optimus}  - install graphics drivers"
	echo "  wm                                  - install window manager/desktop pkgs"
	echo "  dotfiles                            - get dotfiles"
	echo "  vim                                 - install vim specific dotfiles"
	echo "  golang                              - install golang and packages"
	echo "  rust                                - install rust"
	echo "  scripts                             - install scripts"
	echo "  tools                               - install golang, rust, and scripts"
	echo "  dropbear                            - install and configure dropbear initramfs"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	if [[ $cmd == "base" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources

		base
	elif [[ $cmd == "basemin" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources_min

		base_min
	elif [[ $cmd == "apps" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources_apps

		install_apps
	elif [[ $cmd == "graphics" ]]; then
		check_is_sudo

		install_graphics "$2"
	elif [[ $cmd == "wm" ]]; then
		check_is_sudo

		install_wmapps
	elif [[ $cmd == "dotfiles" ]]; then
		get_user
		get_dotfiles
	elif [[ $cmd == "vim" ]]; then
		install_vim
	elif [[ $cmd == "rust" ]]; then
		install_rust
	elif [[ $cmd == "golang" ]]; then
		install_golang "$2"
	elif [[ $cmd == "scripts" ]]; then
		install_scripts
	elif [[ $cmd == "tools" ]]; then
		install_tools
	elif [[ $cmd == "dropbear" ]]; then
		check_is_sudo

		get_user

		install_dropbear
	else
		usage
	fi
}

main "$@"
