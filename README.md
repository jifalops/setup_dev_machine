# setup_dev_machine

Headless installation of several tools for mobile, web, and data science development.
Intended to be the first run command in Terminal for Linux on ChromeOS.

## Getting Started

Download the script from GitHub

```bash
$ curl https://raw.githubusercontent.com/jifalops/setup_dev_machine/master/setup_dev_machine.sh -o setup_dev_machine.sh
```

### Running the script

```bash
$ bash setup_dev_machine.sh TARGETS
```

See [Usage] below for a list of possible targets.

For a full install use the `vscode`, `flutter`, `node`, and `anaconda` targets.

```bash
$ bash setup_dev_machine.sh vscode flutter node anaconda
```

If you use SettingsSync for VSCode, supply the gist and token as parameters to
`--code-settings-sync`

```bash
$ bash setup_dev_machine.sh vscode --code-settings-sync YOUR_GIST YOUR_TOKEN
```

## Usage

```man
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
```