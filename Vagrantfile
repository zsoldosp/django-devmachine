# set: syntax=ruby
# $ vagrant plugin install vagrant-disksize
# $ vagrant plugin install vagrant-env
DOT_PROFILE = "/home/vagrant/.profile"
DOCKER_COMPOSE_VERSION="1.29.2"
DOCKER_VERSION="5:20.10.16~3-0~ubuntu-focal"

Vagrant.configure("2") do |config|
  config.env.enable # Enable vagrant-env(.env)
  config.vm.define ENV["MACHINE_NAME"], primary: true do |ubuntu|
    ubuntu.vm.box = "ubuntu/focal64"
    ubuntu.disksize.size = '30GB'
    #ubuntu.vm.box = "ubuntu/disco64"
    ubuntu.vm.hostname = ENV["MACHINE_NAME"]
    ports_to_forward = [
    ].uniq
    for port in ports_to_forward do
      ubuntu.vm.network "forwarded_port", guest: port, host: port
    end
    ubuntu.ssh.insert_key = false
    ubuntu.ssh.private_key_path  = "ssh/vagrant"
  end

  config.vm.box_download_insecure = false
  config.vm.boot_timeout = 10 * 60

  # to allow forwarded keys
  config.ssh.keys_only = false
  # config.ssh.username = "kevin" username from the env
  config.ssh.forward_agent = true

  # https://stackoverflow.com/a/43583305 - vagrant always creates host dhcp interface first via nat
  # run c:\Program Files\Oracle\VirtualBox\VBoxManage.exe hostonlyif create before first vagrant up --provision
  config.vm.network "private_network", type: "dhcp"

  config.vm.provision "shell", privileged: false, env: { "DOT_PROFILE" => DOT_PROFILE, "EDITOR" => "vim" }, inline: <<-GENERAL
    set -uex
    add_to_profile() {
        var_name=$1
        shift
        value="$*"

        # TODO: override existing?
        if ! grep ${var_name} ${DOT_PROFILE}; then
            echo "export ${var_name}=\"${value}\"" >> ${DOT_PROFILE}
        fi
    }

    if [ ! -z "${EDITOR}" ]; then
      add_to_profile EDITOR ${EDITOR}
    fi
    vagrant_profile=/vagrant/_profile
    pattern=$(echo ${vagrant_profile} | sed 's/\\//./g')
    if [[ -f ${vagrant_profile} ]]; then
        if ! grep ${pattern} ${DOT_PROFILE}; then
            echo ". ${vagrant_profile}" >> ${DOT_PROFILE}
        fi
    fi
    if ! ping -c 1 localhost; then
      echo "127.0.0.1	localhost" | sudo tee -a /etc/hosts || exit $?
    fi
    SOURCES_LIST=/etc/apt/sources.list
    if grep "^deb.*main restricted$" ${SOURCES_LIST}; then
      sudo sed "s/^\(deb\s.*main restricted\)$/\1 universe/g" ${SOURCES_LIST} -i.bkp
      sudo DEBIAN_FRONTEND=noninteractive apt-get update
    fi
    # needed to allow watching for changes
    KEY=fs.inotify.max_user_watches
    SYSCTL_CONF=/etc/sysctl.conf
    if ! grep ${KEY} ${SYSCTL_CONF}; then
        echo ${KEY}=524288 | sudo tee -a ${SYSCTL_CONF} && sudo sysctl -p
    fi
  GENERAL

  config.vm.provision "shell", privileged: false, inline: <<-SWAP
    set -uex
    if [ ! -f /swapfile ]; then
      sudo fallocate -l 4G /swapfile
    fi
    # TODO: I ended up creating a file w/out swap, so move this to login script check?
    if [ ! swapon -s | grep "^\/swapfile" ]; then
      sudo chmod 600 /swapfile
      sudo mkswap /swapfile
      sudo swapon /swapfile
    fi
    if ! grep swapfile /etc/fstab; then
        echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
    fi
    sudo swapon --show
    sudo free -h
  SWAP

  config.vm.provision "shell", privileged: false, env: {"GIT_NAME" => ENV["GIT_NAME"], "GIT_EMAIL" => ENV["GIT_EMAIL"]}, inline: <<-GIT
    set -uex
    env | grep GIT
    if ! which git; then
      sudo DEBIAN_FRONTEND=noninteractive apt-get install git-core --yes
    fi
    GLOBAL_GITIGNORE=~/.gitignore_global
    echo "*.sw[pon]" > ${GLOBAL_GITIGNORE}
    echo "*~" >> ${GLOBAL_GITIGNORE}
    git config --global core.excludesfile ${GLOBAL_GITIGNORE}
    if [ -z "${GIT_NAME}" ]; then
      echo "GIT_NAME env variable must be set" >&2
      exit 1
    fi
    if [ -z "${GIT_EMAIL}" ]; then
      echo "GIT_EMAIL env variable must be set" >&2
      exit 1
    fi
    git config --global user.name "${GIT_NAME}"
    git config --global user.email "${GIT_EMAIL}"
    # TODO: add  from https://stackoverflow.com/a/30998048
    # find-merge = "!sh -c 'commit=$0 && branch=${1:-HEAD} && (git rev-list $commit..$branch --ancestry-path | cat -n; git rev-list $commit..$branch --first-parent | cat -n) | sort -k2 -s | uniq -f1 -    d | sort -n | tail -1 | cut -f2'"
    # show-merge = "!sh -c 'merge=$(git find-merge $0 $1) && [ -n \"$merge\" ] && git show $merge'"
  GIT


  config.vm.provision "shell", privileged: false, inline: <<-SAMBA
    set -uex
    sudo DEBIAN_FRONTEND=noninteractive apt-get install samba cifs-utils --yes
    sudo cp /vagrant/smb.conf /etc/samba/smb.conf
    (echo vagrant; echo vagrant) | sudo smbpasswd -a vagrant
    # use the \\172.28.128.10\relevize network path to connect
  SAMBA

  config.vm.provision "shell", privileged: false, env: { "DOT_PROFILE" => DOT_PROFILE, "GIT_SSH_PRIVATE_KEY_NAME" => ENV["GIT_SSH_PRIVATE_KEY_NAME"] }, inline: <<-GIT_SSH
    set -uex
    SSH_FOLDER=~/.ssh
    SSH_CONFIG=${SSH_FOLDER}/config
    GIT_PROVIDER_DOMAIN=github
    # https://stackoverflow.com/a/24743948/9157
    if ! (grep "${GIT_PROVIDER_DOMAIN}\.com" ${SSH_CONFIG}); then
      # https://stackoverflow.com/a/8467449/9157
      printf "Host ${GIT_PROVIDER_DOMAIN}.com\n    IdentityFile ~/.ssh/${GIT_SSH_PRIVATE_KEY_NAME}\n" >> ${SSH_CONFIG}
    fi
    GUEST_SSH_KEY_PATH=${SSH_FOLDER}/${GIT_SSH_PRIVATE_KEY_NAME}
    SHARED_FOLDER_SSH_KEY_PATH=/vagrant/ssh/${GIT_SSH_PRIVATE_KEY_NAME}
    if [[ ! -f ${SHARED_FOLDER_SSH_KEY_PATH} ]]; then
    	echo "run ssh-keygen and save the ssh key into ${SHARED_FOLDER_SSH_KEY_PATH}"
			exit 2
    fi
    if [[ ! -f ${GUEST_SSH_KEY_PATH} ]]; then
    	cp ${SHARED_FOLDER_SSH_KEY_PATH} ${GUEST_SSH_KEY_PATH}
	chmod 600 ${GUEST_SSH_KEY_PATH}
    fi
		ssh git@github.com -T -o 'StrictHostKeyChecking no' || true
    # To set the host key once into known hosts
    (ssh git@github.com -T -o 'StrictHostKeyChecking no' || true) 2>&1 | grep 'GitHub does not provide shell access'
  GIT_SSH
  
  config.vm.synced_folder "./", "/vagrant"

  config.vm.provision "shell", privileged: false, env: { "DOT_PROFILE" => DOT_PROFILE }, inline: <<-USER_DOT_CONFIG
  SRC=/vagrant/
  for fname in vimrc npmrc; do
    f=${SRC}/_${fname}
    if [[ -f ${f} ]]; then
      ln -sf ${f} ~/.${fname}
    fi
    sudo apt-get install --yes yamllint tree htop net-tools jq unzip
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  done
  mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
  USER_DOT_CONFIG

  config.vm.provision "shell", privileged: false, env: { "DOT_PROFILE" => DOT_PROFILE }, inline: <<-SOURCE_CODE
    TRACE=1 /vagrant/python.sh
  SOURCE_CODE

  config.vm.provider :virtualbox do |vb|
    vb.gui = true
    vb.name = config.vm.hostname
    vb.memory = 1024 * 4
    vb.cpus = 4
  end
_
end
