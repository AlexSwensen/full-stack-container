export MY_CUSTOM_ENV=true

# Source nvm
. /home/circleci/.nvm/nvm.sh

source /usr/local/bin/virtualenvwrapper.sh

workon circle

printf "CUSTOM ENV LOADED\n"