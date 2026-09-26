# Changelog

- 2026-09-26 **1.0.0**
    - Build-only Ubuntu base image with the users and variables of the Ubuntu runtime base, running as root with a shell and `apt`, current package lists and a generated locale, so packages install without `apt-get update` and without warnings
    - The image is published for amd64 and arm64 under one tag, built and published automatically on every change and every week
