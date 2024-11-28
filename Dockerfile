FROM homebrew/brew:latest AS pelican

RUN brew install hugo

EXPOSE 8000

WORKDIR /local-dir
