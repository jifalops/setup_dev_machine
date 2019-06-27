#!/bin/bash
#-------------------------------------------------------------------------------
# Version-dependent variables. PRs welcome :)
# https://github.com/jifalops/setup_dev_machine/pulls

# See https://developer.android.com/studio/#command-tools
ANDROID_TOOLS_URL='https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip'
# See https://flutter.dev/docs/get-started/install/chromeos#install-the-android-sdks
#ANDROID_SDKMANAGER_ARGS='' See the TODO below
ANDROID_INFO_UPDATED='2019-05-30'

# See https://github.com/nvm-sh/nvm/blob/master/README.md#install--update-script
NVM_SETUP_SCRIPT='https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh'
NVM_INFO_UPDATED='2019-05-30'

# See https://www.anaconda.com/distribution/#linux
ANACONDA_SETUP_SCRIPT='https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh'
ANACONDA_INFO_UPDATED='2019-05-30'
#-------------------------------------------------------------------------------

USAGE='
Usage: setup_dev_machine.sh [OPTIONS] TARGET1 [TARGET2 [...]]

OPTIONS
--code-settings-sync GIST TOKEN   VS Code SettingsSync gist and token.
-f, --force                       Install targets that are already installed.
-h, --help                        Show this help message.
-p, --path PATH                   The install path for some targets
                                  (android, flutter, anaconda, miniconda).
                                  Defaults to ~/tools/.

TARGETS
vscode
        Visual Studio Code editor. To include the SyncSettings extension, use
        the --code-settings-gist and --code-settings-token arguments.
flutter
        Installs Flutter from the git repo. Also installs the "android" target.
android
        Installs the Android command line tools, without Android Studio.
node
        Installs nvm and the latest version of node/npm.
anaconda
        Installs the anaconda data science package for python. Includes an
        optimized version of python, pip, jupyter, and many packages used by the
        scientific community.
miniconda
        Stripped version of anaconda that does not pre-install packages.
pip
        Installs pip for Python 3.

Specifying the targets "vscode flutter node anaconda" constitutes a full install.

For information about the SettingsSync extension for VSCode, see
https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync.
'

ALL_TARGETS=(vscode flutter android node anaconda miniconda pip)

# Utility functions
command_exists() {
  $(command -v "$1" >/dev/null 2>&1) && echo 1
}
package_exists() {
  $(dpkg -l "$1" >/dev/null 2>&1) && echo 1
}
is_in_path() {
  [[ $PATH == *"$1"* ]] && echo 1
}

# Parse command-line arguments
targets=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  --code-settings-sync)
    code_settings_gist="$2"
    code_settings_token="$3"
    shift # past argument
    shift # past argument
    shift # past value
    ;;
  -f | --force)
    force_install=1
    shift # past argument
    ;;
  -h | --help)
    echo "$USAGE"
    exit 0
    ;;
  -p | --path)
    install_dir="$2"
    shift # past argument
    shift # past value
    ;;

  *) # unknown option
    targets+=("$1") # save it in an array for later
    shift           # past argument
    ;;
  esac
done
set -- "${targets[@]}" # restore positional parameters

# Validate arg count
if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 1
fi

# Validate VSCode SettingsSync settings
if [ -n "$code_settings_gist" ]; then
  if [ ${#code_settings_gist} -ne 32 ] || [ ${#code_settings_token} -ne 40 ]; then
    echo "Invalid gist or token. Their lengths are 32 and 40 characters, respectively."
    exit 1
  fi
fi

# Validate install_dir
if [ -n "$install_dir" ]; then
  if [ ! -d "$install_dir"]; then
    echo "$install_dir is not a directory."
    exit 1
  fi
else
  install_dir="$HOME/tools"
  # TODO move
  # if [ ${has_target[flutter]} ] && [ -d "$install_dir/flutter" ]; then
  #   echo "$install_dir/flutter already exists."
  #   exit 1
  # fi
  if [ ! -d "$install_dir" ]; then
    mkdir "$install_dir" || exit 1
  fi
fi
cd "$install_dir" || exit 1

# Validate targets list
declare -A has_target
for target in "${targets[@]}"; do
  valid=0
  for t in "${ALL_TARGETS[@]}"; do
    if [ "$target" == "$t" ]; then
      valid=1
      has_target[$t]=1
      break
    fi
  done
  if [ $valid -eq 0 ]; then
    echo "Invalid target $target"
    exit 1
  fi
done


#
# Installers
#

# VS Code with settings-sync
if [ ${has_target[vscode]} ]; then
  echo
  echo "======================================================="
  echo "Installing VS Code by adding it to the apt sources list"
  echo "See https://code.visualstudio.com/docs/setup/linux"
  echo "======================================================="
  echo
  if [ $(command -v code) ]; then
    echo "WARNING: VSCode is already installed."
  fi
  sudo apt-get -y install gnupg
  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
  sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
  sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

  sudo apt-get -y install apt-transport-https
  sudo apt-get update
  sudo apt-get -y install code # or code-insiders

  # Extensions
  code --install-extension dart-code.flutter --force
  code --install-extension ms-python.python --force
  code --install-extension shan.code-settings-sync --force

  if [ -n "$code_settings_gist" ]; then
    sudo apt-get -y install jq
    settings_file="$HOME/.config/Code/User/settings.json"
    sync_file="$HOME/.config/Code/User/syncLocalSettings.json"
    default_sync_settings="{ \"sync.gist\": \"$code_settings_gist\", \"sync.autoDownload\": true, \"sync.autoUpload\": true, \"sync.quietSync\": true }"
    if [ -e "$settings_file" ]; then
      echo 'Applying current settings on top of default sync settings.'
      echo "$default_sync_settings $(cat ${settings_file})" | jq -s add >"$settings_file"
    else
      echo "$default_sync_settings" >"$settings_file"
    fi
    if [ -e "$sync_file" ]; then
      tmp=$(mktemp)
      jq ".token = \"$code_settings_token\"" "$sync_file" >"$tmp" && mv "$tmp" "$sync_file"
    else
      echo "{ \"token\": \"$code_settings_token\" }" >"$sync_file"
    fi
    code
  fi
fi

# Flutter
if [ ${has_target[flutter]} ]; then
  echo
  echo "=========================================================================="
  echo "Setting up Flutter from GitHub (master)"
  echo "See https://flutter.dev/docs/development/tools/sdk/releases"
  echo
  if [ $(command -v flutter) ]; then
    echo "WARNING: flutter is already installed."
  fi
  git clone -b master https://github.com/flutter/flutter.git "$install_dir/flutter"
  "$install_dir/flutter/bin/flutter" --version

  sudo apt-get -y install lib32stdc++6 make clang

  export PATH="$PATH:$install_dir/flutter/bin:$install_dir/flutter/bin/cache/dart-sdk/bin:$HOME/.pub-cache/bin"
  PATH_CHANGES+="$install_dir/flutter/bin:$install_dir/flutter/bin/cache/dart-sdk/bin:$HOME/.pub-cache/bin"
fi

# Android SDK and tools
if [ ${has_target[flutter]} ] || [ ${has_target[android]} ]; then
  echo
  echo "==================================================="
  echo "Setting up the Android SDK (without Android Studio)"
  echo "See https://developer.android.com/studio/#command-tools"
  echo
  if [ $(command -v adb) ] && [ $(command -v sdkmanager) ] && [ $(command -v emulator) ]; then
    echo "WARNING: android tools are already installed."
  fi
  sudo apt-get -y install default-jre default-jdk wget

  if [ -z "$ANDROID_HOME" ]; then
    export ANDROID_HOME="$install_dir/android"
    echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >>"$HOME/.profile"
  fi

  mkdir "$ANDROID_HOME" >/dev/null 2>&1
  cd "$ANDROID_HOME"

  wget "$ANDROID_TOOLS_URL"
  unzip sdk-tools-linux*.zip*
  rm sdk-tools-linux*.zip*

  export PATH="$PATH:$ANDROID_HOME/tools/bin:$ANDROID_HOME/tools"
  PATH_CHANGES+=':$ANDROID_HOME/tools/bin:$ANDROID_HOME/tools'

  # Squelches a repeated warning
  mkdir "$HOME/.android" >/dev/null 2>&1
  touch "$HOME/.android/repositories.cfg"

  yes | sdkmanager --licenses
  # TODO pass this as a version-dependent variable.
  sdkmanager "build-tools;28.0.3" "emulator" "tools" "platform-tools" "platforms;android-28" "extras;google;google_play_services" "extras;google;webdriver" "system-images;android-28;google_apis_playstore;x86_64"

  export PATH="$PATH:$ANDROID_HOME/platform-tools"
  PATH_CHANGES+=':$ANDROID_HOME/platform-tools'

  cd "$install_dir"
fi

# Node and npm (via nvm)
if [ ${has_target[node]} ]; then
  echo
  echo "======================================================="
  echo "Installing Node and npm via Node Version Manager (nvm)"
  echo "See https://github.com/nvm-sh/nvm/blob/master/README.md"
  echo
  if [ $(command -v nvm) ]; then
    echo "WARNING: nvm is already installed."
  fi
  curl -o- "$NVM_SETUP_SCRIPT" | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

  nvm install node

  # Firebase tools
  npm install -g firebase-tools
fi

# Anaconda data science kit. Includes pip, spyder, jupyter, and many packages.
if [ ${has_target[anaconda]} ]; then
  echo
  echo "================================"
  echo "Installing Anaconda for Python 3"
  echo
  if [ $(command -v anaconda) ]; then
    echo "WARNING: anaconda already installed."
  fi
  if [ ! $(command -v wget) ]; then
    sudo apt-get -y install wget
  fi
  wget "$ANACONDA_SETUP_SCRIPT" -O "$install_dir/anaconda.sh"
  bash "$install_dir/anaconda.sh" -b -p "$install_dir/anaconda"
  rm "$install_dir/anaconda.sh"

  # Create a launcher icon for Spyder
  if [ ! -d "$HOME/.local/share/applications" ]; then
    mkdir "$HOME/.local/share/applications"
  fi
  cat <<EOF >"$HOME/.local/share/applications/spyder.desktop"
[Desktop Entry]
Name=Spyder
GenericName=Text Editor
Exec=$install_dir/anaconda/bin/spyder
Icon=$install_dir/anaconda/lib/python3.7/site-packages/spyder/images/spyder.svg
Type=Application
StartupNotify=false
StartupWMClass=Spyder
Categories=Utility;TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;
Actions=new-empty-window;
Keywords=spyder;

X-Desktop-File-Install-Version=0.23

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=$install_dir/anaconda/bin/spyder
Icon=$install_dir/anaconda/lib/python3.7/site-packages/spyder/images/spyder.svg
EOF
  sudo update-desktop-database

  export PATH="$PATH:$install_dir/anaconda/bin:$install_dir/anaconda/condabin"
  PATH_CHANGES+=":$install_dir/anaconda/bin:$install_dir/anaconda/condabin"
fi

# Miniconda.
if [ ${has_target[miniconda]} ]; then
  echo
  echo "================================"
  echo "Installing Miniconda for Python 3"
  echo
  if [ $(command -v conda) ] && [ ! $(command -v anaconda) ]; then
    echo "WARNING: miniconda already installed."
  fi
  if [ ! $(command -v wget) ]; then
    sudo apt-get -y install wget
  fi
  wget "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O "$install_dir/miniconda.sh"
  bash "$install_dir/miniconda.sh" -b -p "$install_dir/miniconda"
  rm "$install_dir/miniconda.sh"
  export PATH="$PATH:$install_dir/miniconda/bin:$install_dir/miniconda/condabin"
  PATH_CHANGES+=":$install_dir/miniconda/bin:$install_dir/miniconda/condabin"
fi

# pip for Python 3
if [ ${has_target[pip]} ] && [ ! ${has_target[anaconda]} ] && [ ! ${has_target[miniconda]} ]; then
  echo
  echo "================================"
  echo "Installing pip for Python 3"
  echo
  sudo apt-get -y install python3-pip
fi

# ChromeOS specific
if [ -d /mnt/chromeos ] && [ ! -e "$HOME/Downloads" ]; then
  ln -s /mnt/chromeos/MyFiles/Downloads/ "$HOME/Downloads"
fi

# Extras
type la >/dev/null 2>&1 || echo 'alias la="ls -a"' >>"$HOME/.profile"
type ll >/dev/null 2>&1 || echo 'alias ll="ls -la"' >>"$HOME/.profile"
sudo apt-get -y install software-properties-common

# Finishing up
echo "export PATH=\"$PATH_CHANGES:\$PATH\"" >>"$HOME/.profile"

if [ ${has_target[flutter]} ]; then
  flutter doctor
fi

echo
echo "Setup complete, restart your terminal session or source ~/.profile."
