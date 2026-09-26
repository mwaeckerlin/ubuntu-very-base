# Minimum Ubuntu Docker Image with Definitions and Non Root User

Minimal docker base image built on ubuntu. Use this image as base in your build stages, then add an additional stage for production, where you inherit from [mwaeckerlin/ubuntu-scratch](https://github.com/mwaeckerlin/ubuntu-scratch) and where you copy only the required files and dependencies.

It is the Ubuntu counterpart of [mwaeckerlin/very-base](https://github.com/mwaeckerlin/very-base): the same role, the same users and the same variables, with `apt` instead of `apk`. Use it where a build needs the GNU C library or packages that only Ubuntu provides.

Image size: ca. 163MB (depends on `ubuntu`, so it may vary from build to build)

## Build-Only Image

This image is **build-only** — use it exclusively in build stages of a multi-stage Dockerfile and **never in production**. It contains a shell and a package manager and it runs as `root` so that build stages can install packages; that is exactly what a hardened runtime image must not do. The final stage of a production image always inherits from [mwaeckerlin/ubuntu-scratch](https://github.com/mwaeckerlin/ubuntu-scratch).

The package lists of `apt` stay in the image, so `RUN $PKG_INSTALL gcc` works without a preceding `apt-get update`; the weekly rebuild keeps them current. `DEBIAN_FRONTEND` is `noninteractive`, and the locale of `LANG` is generated, also again in a derived image that sets the build argument `lang`.

See [mwaeckerlin/nginx](https://github.com/mwaeckerlin/nginx) as an example on how to build a service using [mwaeckerlin/very-base](https://github.com/mwaeckerlin/very-base); a build on this image follows the same pattern.
