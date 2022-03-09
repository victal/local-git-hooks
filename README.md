# Git Local Hooks

A series of git hooks which I find useful but may not always be easy to configure company-wide or repository-wide;

## Installation/usage:

This repository takes advantage of the global `core.hooksPath` configuration, so instructions will assume you do not already have a setup with a centralized hook directory. If you do, you probably know how to tweak your config to take advantage of the hooks you want.

1. Clone this repository to a given directory, say "$HOME/config/git-local-hooks"
2. Configure your global git configuration to use the `./hooks` directory on this repository as its central hooks dir:
    `git config --global core.hooksPath "$HOME/config/git-local-hooks/hooks"
3. That's it! Now git will start using the scripts on the ./hooks directory instead of searching for hooks inside a given repository .git folder (see https://git-scm.com/docs/git-config#Documentation/git-config.txt-corehooksPath for more information)

## I'm using husky and this ~expletive~ does not work! What gives?

Husky is a popular npm package to manage git hooks inside a given repository. 
Unfortunately, from v7 onwards, it also works by overwriting the `core.hooksPath` configuration on the repositories it is installed, which means our local hooks don't work automatically in husky-managed repos.

In order to run our local hooks on a husky managed repo, we have to add the following snippet at the beginning of every hook husky creates under `./husky`: 

```sh
# run the global hook if it is present
if [ -e "$(git config --global core.hookspath)/pre-commit" ]; then
    "$(git config --global core.hookspath)/pre-commit" "$@"
fi
```

If there is no husky hook for an action for which you want to use the corresponding local hooks (e.g. no `./.husky/pre-commit`), you must create an executable `./.husky/pre-commit` file that just calls the global hook:


```sh
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# run the global hook if it is present
if [ -e "$(git config --global core.hookspath)/pre-commit" ]; then
    "$(git config --global core.hookspath)/pre-commit" "$@"
fi
```

## Implemented hooks

pre-commit/

- **branch_name.sh**: Validates that new branches created from a given "main branch" are named according to a provided regexp.
  Provide the following variables at pre-commit/branch_name.env in order for the hook to run:
    - MAIN_BRANCH="the branch your new branches are created from"
    - VALID_BRANCH_REGEXP="a regexp that matches your preferred branch format"

- **jenkinsfile.sh**: Validates every Jenkinsfile listed in the current commit changed files using the Jenkins API.
  (which means you need a running Jenkins instance and valid credentials to use this hook).
  Provide the following variables at pre-commit/jenkinsfile.env in order for the hook to run:
  - JENKINS_USER='jenkins username with which to run the hook'
  - JENKINS_PASSWD='Not your password, but an API Token created at $YOUR_JENKINS_URL/me/configure'
  - JENKINS_URL='Root URL for your jenkins instance'
  - HTTP_PROXY or HTTPS_PROXY: If you need to use a proxy to access your jenkins instance and you do not already set the appropriate env-vars, you can add them to the jenkinsfile.env file for that

- **kubernetes.sh**: Validates changed kubernetes manifests (files defined by a regexp, which defaults to any .yml or .yaml file inside a `kubernetes` directory). Uses kubeconform or kubeval for validation, according to which is installed (kubeconform is chosen over kubeval if both are present)
  Provide the following variables at pre-commit/kubernetes.env in order to customize the hook:
    - MANIFEST_FILE_PATTERN: file pattern to validate if found
