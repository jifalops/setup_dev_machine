# setup_dev_machine

Headless installation of several tools for mobile, web, and data science development.
Intended to be the first run command in Terminal for Linux on ChromeOS.

## Get the script

```bash
$ curl https://raw.githubusercontent.com/jifalops/setup_dev_machine/master/setup_dev_machine.sh -o setup_dev_machine.sh
```

```bash
$ bash setup_dev_machine.sh --help
```

### Install some targets

```bash
$ bash setup_dev_machine.sh vscode flutter node anaconda
```

### Other examples

Integrate with the VS Code SettingsSync extension

```bash
$ bash setup_dev_machine.sh vscode --code-settings-sync YOUR_GIST YOUR_TOKEN
```

Setup git name and email

```bash
$ bash setup_dev_machine.sh --git-config YOUR_NAME YOUR_EMAIL
```

Initialize your workspace (See below for details)

```bash
$ bash setup_dev_machine.sh --workspace DIRECTORY GIT_REMOTE
```

## Backing up a workspace directory

A workspace directory contains subdirectories with git repos. The idea is to
have a text file with a list of repos that should be cloned when setting up the
dev machine. There is a separate script to manage this process,
`workspace_repos.sh`.

Before you can setup the new machine/container with those repos, you have to back
them up from an existing machine. If you do not have repos you want to back up,
you can skip this section.

### Make sure you have the script

```bash
$ curl https://raw.githubusercontent.com/jifalops/setup_dev_machine/master/workspace_repos.sh -o workspace_repos.sh
```

#### First time, create the remote repository

For example, on GitHub, create a repository named `workspace_repos`.

Then run the script with the `init` command. Be sure to replace repo URL with
your own.

```bash
# From your workspace directory.
$ workspace_repos.sh init git@github.com:USERNAME/workspace_repos.git
$ workspace_repos.sh backup  # Creates repos.txt and pushes it to origin master.
```

#### Subsequent runs

```bash
$ workspace_repos.sh backup  # Creates repos.txt and pushes it to origin master.
```

### Note about containers

Many containers have been created to test this script on a chromebook with Linux
(Beta). Since my git remotes all use ssh, setting up a workspace directory
requires having ssh setup with the proper keys. I have found it very helpful to
keep my `.ssh/` directory as a top level folder in Chrome and "share it with
Linux". This may be ill advised, but it helps save time. Then after creating a
container, run `cp -r /mnt/chromeos/MyFiles/.ssh ~/` so that I have access to my
repos.

> On Chrome 76 beta channel, sharing with Linux is buggy for secondary VMs, but
seems consistent when using the termina VM.

#### The super-duper setup me computer command
Want everything done with one command? Me too.
This assumes you are on a chromebook and sharing your .ssh folder with linux.
If you aren't, you can leave out the first command. Otherwise just replace with
your info and keep in a safe place.

```bash
cp -r /mnt/chromeos/MyFiles/.ssh ~/ && curl https://raw.githubusercontent.com/jifalops/setup_dev_machine/master/setup_dev_machine.sh -o setup_dev_machine.sh && bash setup_dev_machine.sh vscode flutter node --code-settings-sync YOUR_GIST YOUR_TOKEN --workspace code  git@github.com:USERNAME/workspace_repos.git --git-config "YOUR NAME" "YOUR EMAIL"
```


## Usage

```man
Usage: setup_dev_machine.sh [OPTIONS] TARGET1 [TARGET2 [...]]

OPTIONS
--code-settings-sync GIST TOKEN   VS Code SettingsSync gist and token.
-f, --force                       Install targets that are already installed.
-g, --git-config NAME EMAIL       Set the global git config name and email address.
-h, --help                        Show this help message.
-p, --path PATH                   The install path for some targets
                                  (android, flutter, anaconda, miniconda).
                                  Defaults to ~/tools/. Note for anaconda, the
                                  spyder launcher icon is created in ~/.local.
-w, --workspace DIRECTORY REMOTE  Setup a workspace folder in DIRECTORY and clone
                                  the list of repos at (REMOTE git repo)/repos.txt
                                  DIRECTORY is a name, not a path. It will be
                                  created under $HOME.

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

## Usage
Usage: workspace_repos.sh COMMAND

COMMANDS
backup        Find all the git repos that are a direct child of the current
              directory, and write their origin remote to "repos.txt". Commit
              the changes and push to origin master.
clone         Pull from origin master and then run git clone on each line of
              "repos.txt".
init REMOTE   Clone REMOTE or initialize a git repository with REMOTE
