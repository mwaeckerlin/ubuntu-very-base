# Features

Numbered register of every feature; a number is never reused. Every feature is covered by tests listed in [TESTS.md](TESTS.md); the guard `tests/docs-contract.sh` fails when a feature has no test.

- **F1 — Current Ubuntu for build stages.** The latest Ubuntu with every package upgraded at build time, a shell and the package manager `apt`, reachable through `$PKG_INSTALL`, `$PKG_REMOVE` and `$PKG_SEARCH`. The package lists stay in the image, so `$PKG_INSTALL` works without a preceding `apt-get update`, and `DEBIAN_FRONTEND` is `noninteractive`, so `apt` installs without asking and without warnings.
- **F2 — Root for building.** The image runs as `root`, so a build stage can install packages. It is build-only and never the final stage of a production image.
- **F3 — The users and variables of mwaeckerlin/ubuntu-scratch.** `somebody` (100:1000) and `coder` (101:1001) exist with the same ids as in the runtime base and in `mwaeckerlin/scratch`, the default user `ubuntu` of the Ubuntu image and its home are gone, and every variable of `mwaeckerlin/ubuntu-scratch` is set, so a build stage prepares files with `$ALLOW_USER` for the runtime user.
- **F4 — Language.** `LANG` defaults to `en_US.UTF-8`; a derived image sets another one with the build argument `lang`. The locale of `LANG` is generated, in the image and in every derived image.
- **F5 — Published for amd64 and arm64.** Every push builds the image natively for both architectures and publishes it under one tag on Docker Hub, with the reusable workflow of `mwaeckerlin/scratch`.
