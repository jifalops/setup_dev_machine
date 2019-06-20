#!/bin/bash
echo
echo "======================================================="
echo "Installing VS Code by adding it to the apt sources list"
echo "See https://code.visualstudio.com/docs/setup/linux"
echo
sudo curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt-get -y install apt-transport-https
sudo apt-get update
sudo apt-get -y install code # or code-insiders

# Extensions
code --install-extension dart-code.flutter --force
code --install-extension ms-python.python --force
code --install-extension shan.code-settings-sync --force

if [ $# -eq 2 ]; then
  # Setup SettingsSync extension and start VS Code to allow it to sync.
  echo "{ \"sync.gist\": \"$1\", \"sync.autoDownload\": true, \"sync.autoUpload\": true, \"sync.quietSync\": true }" > "$HOME/.config/Code/User/settings.json"
  sudo apt-get -y install jq
  tmp=$(mktemp)
  jq ".token = \"$2\"" "$HOME/.config/Code/User/syncLocalSettings.json" > "$tmp" && mv "$tmp" "$HOME/.config/Code/User/syncLocalSettings.json"
  code
fi