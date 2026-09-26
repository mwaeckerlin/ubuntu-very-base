FROM ubuntu AS ubuntu
ARG lang="en_US.UTF-8"
ARG DEBIAN_FRONTEND="noninteractive"
# the package lists stay in the image: $PKG_INSTALL has no index of its own
RUN apt-get update
RUN apt-get dist-upgrade -y --no-install-recommends --no-install-suggests
# musl ignores LANG, glibc needs the locale generated, or every perl and apt
# call of a build stage warns that the locale is missing
RUN apt-get install -y --no-install-recommends --no-install-suggests locales
RUN locale-gen "${lang}"
# the users come from mwaeckerlin/ubuntu-scratch; drop the image's own user
# and its home, since only /etc/passwd and /etc/group are replaced below
RUN userdel -r ubuntu

FROM mwaeckerlin/ubuntu-scratch AS user

FROM mwaeckerlin/ubuntu-scratch
ARG lang="en_US.UTF-8"

ENV CONTAINERNAME="ubuntu-very-base"
# build stages have no terminal: apt must not ask
ENV DEBIAN_FRONTEND="noninteractive"
COPY --from=ubuntu / /
COPY --from=user /etc/passwd /etc/passwd
COPY --from=user /etc/group /etc/group
COPY --from=user --chown=${RUN_USER} /home/${RUN_USER}  /home/${RUN_USER}
CMD ["/bin/sh"]
# build-only image: stays root so that build stages can install packages;
# never use it as final stage — production stages inherit from mwaeckerlin/ubuntu-scratch
USER root

# allow derived images to overwrite the language
ONBUILD ARG lang
ONBUILD ENV LANG=${lang:-${LANG}}
ONBUILD RUN locale-gen "${LANG}"
