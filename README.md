# Rigup Deployment Tool

Rigup (as in to set up) is a tool inspired by Capistrano and Inploy (https://github.com/dcrec1/inploy) with some original ideas for deploying web applications.

* Is a command line tool using Ruby and Thor (https://github.com/erikhuda/thor).
* It borrows the folder structure and naming of things from Capistrano
* However, like Inploy it executes on the destination server, and pulls code from a git repository
* rigup.yml files are not kept in version control, but contain deployment values for branch, commit etc.
* The top level site folder rigup.yml is automatically generated and may be edited to specify options for what should be deployed below
* A copy of the top level rigup.yml is copied into each release folder so you have a record of what was released and installed there.
* It separates delivering of files from installing, configuring and launching the application. This solves several problems. eg. you can't logically
configure what branch to install, in a file that is itself on a branch in the repository
* Installation, configuration, restart etc are performed by calling arbitrary specified script(s). This script may be written in any language and can be included in the application repository. Thor (https://github.com/erikhuda/thor) is recommended as a default.

## Terms

**Deploy:** the complete process, including updating the cache, creating a release, installing it, making it live, restarting the web server etc.

**Install:** like a desktop application installer - modify repository files as required to run the application

**Restart:** full restart of web server in order to reload configuration changes caused by deployment

**Block:** show maintenance page while system is under maintenance

**Unblock:** remove maintenance page if present

**Stage:** defaults to "live" but could be "staging", "test", "dev" etc. Used to differentiate between different kinds of installs

## Usage

Setup inspired by git :

\> rigup new https://myco@bitbucket.org/myco/website.git myco-website

* Eventually this will support options for specifiying branch, commit, stage etc
* Creates folder structure like Capistrano under myco-website folder
* Creates rigup.yml specifying repository, branch, commit, stage etc and commands to execute for install, block, restart and unblock.

\> rigup deploy myco-website

* Creates or updates cache of git@bitbucket.org:myco/website.git according to options and rigup.yml
* Creates release timestamp folder under releases/ containing contents of cache (without .git folder) and copy of rigup.yml specifiying the repo, branch, commit etc within
* Calls install command
* Calls block command
* Updates symbolic link "current" to point to latest release
* Calls restart command
* Calls unblock command
* Cleans up old release folders
