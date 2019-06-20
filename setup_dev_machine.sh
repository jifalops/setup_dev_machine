#!/bin/bash
#-------------------------------------------------------------------------------
# Version-dependent variables. PRs welcome :)

# See https://developer.android.com/studio/#command-tools
ANDROID_TOOLS_URL='https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip'
# See https://flutter.dev/docs/get-started/install/chromeos#install-the-android-sdks
ANDROID_SDKMANAGER_ARGS='"build-tools;28.0.3" "emulator" "tools" "platform-tools" "platforms;android-28" "extras;google;google_play_services" "extras;google;webdriver" "system-images;android-28;google_apis_playstore;x86_64"'
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
-h, --help                        Show this help message.
-p, --path PATH                   The install path for some targets
                                  (android, flutter, anaconda, miniconda).
                                  Defaults to ~/tools/.
--code-settings-sync GIST TOKEN   VS Code SettingsSync gist and token.

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

# Parse command-line arguments
TARGETS=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -h | --help)
    echo "$USAGE"
    exit 0
    ;;
  -p | --path)
    INSTALL_DIR="$2"
    shift # past argument
    shift # past value
    ;;
  --code-settings-sync)
    CODE_SETTINGS_GIST="$2"
    CODE_SETTINGS_TOKEN="$3"
    shift # past argument
    shift # past argument
    shift # past value
    ;;
  *) # unknown option
    TARGETS+=("$1") # save it in an array for later
    shift           # past argument
    ;;
  esac
done
set -- "${TARGETS[@]}" # restore positional parameters

# Validate arg count
if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 1
fi

# Validate targets
declare -A HAS_TARGET
for target in "${TARGETS[@]}"; do
  VALID=0
  for t in "${ALL_TARGETS[@]}"; do
    if [ "$target" == "$t" ]; then
      VALID=1
      HAS_TARGET[$t]=1
      break
    fi
  done
  if [ $VALID -eq 0 ]; then
    echo "Invalid target $target"
    exit 1
  fi
done

# Validate INSTALL_DIR
if [ -n "$INSTALL_DIR" ]; then
  if [ ! -d "$INSTALL_DIR"]; then
    echo "$INSTALL_DIR is not a directory."
    exit 1
  fi
else
  INSTALL_DIR="$HOME/tools"
  if [ ${HAS_TARGET[flutter]} -eq 1 ] && [ -d "$INSTALL_DIR/flutter" ]; then
    echo "$INSTALL_DIR/flutter already exists."
    exit 1
  fi
  if [ ! -d "$INSTALL_DIR" ]; then
    mkdir "$INSTALL_DIR"
  fi
fi

cd "$INSTALL_DIR"

# Validate VSCode SettingsSync settings
if [ -n "$CODE_SETTINGS_GIST" ]; then
  if [ ${#CODE_SETTINGS_GIST} -ne 32 ] || [ ${#CODE_SETTINGS_TOKEN} -ne 40 ]; then
    echo "Invalid gist or token. Their lengths are 32 and 40 characters, respectively."
    exit 1
  fi
fi


# Prerequisites
sudo apt-get -y install wget make clang software-properties-common

# VS Code with settings-sync
if [ ${HAS_TARGET[vscode]} -eq 1 ]; then
  echo
  echo "======================================================="
  echo "Installing VS Code by adding it to the apt sources list"
  echo "See https://code.visualstudio.com/docs/setup/linux"
  echo
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

  if [ -n "$CODE_SETTINGS_GIST" ]; then
    sudo apt-get -y install jq
    settings_file="$HOME/.config/Code/User/settings.json"
    default_sync_settings="{ \"sync.gist\": \"$CODE_SETTINGS_GIST\", \"sync.autoDownload\": true, \"sync.autoUpload\": true, \"sync.quietSync\": true }"
    if [ -e "$settings_file" ]; then
      echo 'Applying current settings on top of default sync settings.'
      echo "$default_sync_settings $(cat ${settings_file})" | jq -s add >"$settings_file"
    else
      echo "$default_sync_settings" >"$settings_file"
    fi
    tmp=$(mktemp)
    jq ".token = \"$CODE_SETTINGS_TOKEN\"" "$HOME/.config/Code/User/syncLocalSettings.json" >"$tmp" && mv "$tmp" "$HOME/.config/Code/User/syncLocalSettings.json"
    code
  fi
fi

# Flutter
if [ ${HAS_TARGET[flutter]} -eq 1 ]; then
  echo
  echo "=========================================================================="
  echo "Setting up Flutter from GitHub (master)"
  echo "See https://flutter.dev/docs/development/tools/sdk/releases"
  echo

  git clone -b master https://github.com/flutter/flutter.git "$INSTALL_DIR/flutter"
  "$INSTALL_DIR/flutter/bin/flutter" --version

  sudo apt-get -y install lib32stdc++6

  export PATH="$PATH:$INSTALL_DIR/flutter/bin:$INSTALL_DIR/flutter/bin/cache/dart-sdk/bin:$HOME/.pub-cache/bin"
  PATH_CHANGES+="$INSTALL_DIR/flutter/bin:$INSTALL_DIR/flutter/bin/cache/dart-sdk/bin:$HOME/.pub-cache/bin"
fi

# Android SDK and tools
if [ ${HAS_TARGET[flutter]} -eq 1 ] || [ ${HAS_TARGET[android]} -eq 1 ]; then
  echo
  echo "==================================================="
  echo "Setting up the Android SDK (without Android Studio)"
  echo "See https://developer.android.com/studio/#command-tools"
  echo

  sudo apt-get -y install default-jre
  sudo apt-get -y install default-jdk

  export ANDROID_HOME="$INSTALL_DIR/android"
  echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >>"$HOME/.profile"

  mkdir "$ANDROID_HOME"
  cd "$ANDROID_HOME"

  wget "$ANDROID_TOOLS_URL"
  unzip sdk-tools-linux*
  rm sdk-tools-linux*.zip*

  export PATH="$PATH:$ANDROID_HOME/tools/bin:$ANDROID_HOME/tools"
  PATH_CHANGES+=':$ANDROID_HOME/tools/bin:$ANDROID_HOME/tools'

  # Squelches a repeated warning
  mkdir "$HOME/.android"
  touch "$HOME/.android/repositories.cfg"

  yes | sdkmanager --licenses
  sdkmanager "$ANDROID_SDKMANAGER_ARGS"

  export PATH="$PATH:$ANDROID_HOME/platform-tools"
  PATH_CHANGES+=':$ANDROID_HOME/platform-tools'

  cd "$INSTALL_DIR"
fi

# Node and npm (via nvm)
if [ ${HAS_TARGET[node]} -eq 1 ]; then
  echo
  echo "======================================================="
  echo "Installing Node and npm via Node Version Manager (nvm)"
  echo "See https://github.com/nvm-sh/nvm/blob/master/README.md"
  echo

  curl -o- "$NVM_SETUP_SCRIPT" | bash
  source "$HOME/.bashrc"
  nvm install node

  # Firebase tools
  npm install -g firebase-tools
fi

# Anaconda data science kit. Includes pip, spyder, jupyter, and many packages.
if [ ${HAS_TARGET[anaconda]} -eq 1 ]; then
  echo
  echo "================================"
  echo "Installing Anaconda for Python 3"
  echo
  curl -s "$ANACONDA_SETUP_SCRIPT" -o "$INSTALL_DIR/anaconda.sh"
  bash "$INSTALL_DIR/anaconda.sh" -b -p "$INSTALL_DIR/anaconda"
  rm "$INSTALL_DIR/anaconda.sh"

  # Create a launcher icon for Spyder
  cat <<EOF >"$HOME/.local/share/applications/spyder.desktop"
[Desktop Entry]
Name=Spyder
GenericName=Text Editor
Exec=$INSTALL_DIR/anaconda/bin/spyder
Icon=$INSTALL_DIR/anaconda/lib/python3.7/site-packages/spyder/images/spyder.svg
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
Exec=$INSTALL_DIR/anaconda/bin/spyder
Icon=$INSTALL_DIR/anaconda/lib/python3.7/site-packages/spyder/images/spyder.svg
EOF
  sudo update-desktop-database

  export PATH="$PATH:$INSTALL_DIR/anaconda/bin:$INSTALL_DIR/anaconda/condabin"
  PATH_CHANGES+=":$INSTALL_DIR/anaconda/bin:$INSTALL_DIR/anaconda/condabin"
fi

# Miniconda.
if [ ${HAS_TARGET[miniconda]} -eq 1 ]; then
  echo
  echo "================================"
  echo "Installing Anaconda for Python 3"
  echo
  curl -s "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -o "$INSTALL_DIR/miniconda.sh"
  bash "$INSTALL_DIR/miniconda.sh" -b -p "$INSTALL_DIR/miniconda"
  rm "$INSTALL_DIR/miniconda.sh"
  export PATH="$PATH:$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/miniconda/condabin"
  PATH_CHANGES+=":$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/miniconda/condabin"
fi

# pip for Python 3
if [ ${HAS_TARGET[pip]} -eq 1 ] && [ ${HAS_TARGET[anaconda]} -ne 1 ] && [ ${HAS_TARGET[miniconda]} -ne 1 ]; then
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

# Finishing up
echo "export PATH=\"$PATH_CHANGES:\$PATH\"" >>"$HOME/.profile"

if [ ${HAS_TARGET[flutter]} -eq 1 ]; then
  flutter doctor
fi

echo
echo "Setup complete, restart your terminal session or source ~/.profile."
