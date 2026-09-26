# Tests

Register of all tests, sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything; the guard `tests/docs-contract.sh` fails when a feature has no test entry here.

## Image contract

- **F1** `tests/config-contract.sh` › package_manager_works, package_install_works, package_install_silent, env_PKG_INSTALL — `$PKG_SEARCH` finds the Ubuntu package lists, and `$PKG_INSTALL` installs a package without a preceding `apt-get update` and without a warning.
- **F2** `tests/config-contract.sh` › runs_as_root — build stages run as uid 0.
- **F3** `tests/config-contract.sh` › user_somebody, user_coder, ids_somebody, ids_coder, no_user_ubuntu, run_home_and_allow_user, env_RUN_USER, env_BUILD_USER, env_CONTAINERNAME — the users, the home and the variables of the runtime base, and no trace of the default user `ubuntu`.
- **F4** `tests/config-contract.sh` › env_LANG, locale_generated, child_lang_build_arg, child_locale_generated — the default language and its generated locale, and a child image built with `--build-arg lang=de_CH.UTF-8` carries that language with its locale generated.

## Workflow contract

- **F5** `tests/workflow-contract.sh` of `mwaeckerlin/scratch` — the reusable workflow selects exactly the images a repository publishes; this repository calls it from `.github/workflows/docker.yml`.
