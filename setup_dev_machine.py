import argparse
from argparse import RawTextHelpFormatter
import subprocess
import re

# Version-dependent variables. PRs welcome :)

# See https://developer.android.com/studio/#command-tools
ANDROID_TOOLS_URL = 'https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip'
# See https://developer.android.com/studio/#downloads
ANDROID_STUDIO_URL = 'https://dl.google.com/dl/android/studio/ide-zips/3.4.1.0/android-studio-ide-183.5522156-linux.tar.gz'
# See https://flutter.dev/docs/get-started/install/chromeos#install-the-android-sdks
ANDROID_SDKMANAGER_ARGS = '"build-tools;28.0.3" "emulator" "tools" "platform-tools" "platforms;android-28" "extras;google;google_play_services" "extras;google;webdriver" "system-images;android-28;google_apis_playstore;x86_64"'
ANDROID_INFO_UPDATED = '2019-05-30'

# See https://github.com/nvm-sh/nvm/blob/master/README.md#install--update-script
NVM_SETUP_SCRIPT = 'https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh'
NVM_INFO_UPDATED = '2019-05-30'

ANACONDA_SETUP_SCRIPT = 'https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh'
ANACONDA_INFO_UPDATED = '2019-05-30'

PYCHARM_ARCHIVE_URL = 'https://download.jetbrains.com/python/pycharm-community-2019.1.3.tar.gz'
PYCHARM_INFO_UPDATED = '2019-05-30'


# Links to setup documents.
VSCODE_SETUP_DOC = 'https://code.visualstudio.com/docs/setup/linux'
FLUTTER_SETUP_DOC = 'https://flutter.dev/docs/development/tools/sdk/releases'
ANDROID_SETUP_DOC = 'https://developer.android.com/studio/#downloads'
NVM_SETUP_DOC = 'https://github.com/nvm-sh/nvm/blob/master/README.md'
ANACONDA_SETUP_DOC = 'https://www.anaconda.com/distribution/#linux'

parser = argparse.ArgumentParser(description='''
Headless installation of several development tools.

TARGETS

vscode
        Visual Studio Code editor. To include the SyncSettings extension, use
        the --code-settings-gist and --code-settings-token arguments.
flutter
        Installs Flutter from the git repo. Also installs the "android" target.
android
        Installs the Android command line tools, without Android Studio.
android-studio
        Android installs will include Android Studio.
node
        Installs nvm and the latest version of node/npm.
anaconda
        Installs the anaconda data science package for python. Includes an
        optimized version of python, pip, jupyter, and many packages used by the
        scientific community.
miniconda
        Stripped version of anaconda that doesn't pre-install packages.
pip
        Installs pip for Python 3.
chromeos
        Additional functionality for ChromeOS devices. Symlinks the ChromeOS
        Downloads folder to ~/Downloads when it is shared with Linux, adds bash
        aliases for ll and la.
''', formatter_class=RawTextHelpFormatter)
parser.add_argument('-p', '--path', metavar='PATH', default='/usr/local',
                    help='Where to install programs. Defaults to "/usr/local"')
parser.add_argument('-t', '--targets', metavar='TARGET1,TARGET2,...',
                    required=True,
                    help='The targets to install. Example: "vscode,flutter,node,anaconda,chromeos". See the help text for options.')
parser.add_argument('--code-settings-gist', metavar='GIST',
                    help='SettingsSync for VS Code will use this GitHub gist ID.')
parser.add_argument('--code-settings-token', metavar='GIST',
                    help='SettingsSync for VS Code will use this auth token.')
args = parser.parse_args()

def split_unquoted_whitespace(s):
  return re.findall(r'(?:[^\s,"]|"(?:\\.|[^"])*")+', s)

def shell(cmd):
  return subprocess.run(split_unquoted_whitespace(cmd))

if 'vscode' in args.targets:
