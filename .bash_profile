source /home/circleci/.bashrc

export MY_CUSTOM_ENV=true

# Source nvm
. /home/circleci/.nvm/nvm.sh

printf "CUSTOM ENV LOADED\n"