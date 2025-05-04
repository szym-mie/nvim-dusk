FROM fedora:latest@sha256:ee88ab8a5c8bf78687ddcecadf824767e845adc19d8cdedb56f48521eb162b43

RUN dnf install -y neovim

RUN useradd -m dev
USER dev
WORKDIR /home/dev
CMD [ "nvim" ]