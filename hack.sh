#!/bin/bash

# Configs
COLOR_RED='\033[1;31m';
COLOR_BLUE='\033[1;34m';
COLOR_CYAN='\033[1;36m';
COLOR_GREEN='\033[1;32m';
COLOR_YELLOW='\033[1;33m';
COLOR_DEFAULT='\033[0m';

# Username for the survivor
USER_NAME="tmanoilov";

# Check if WP-CLI is installed.
if ! command -v 'wp' &> /dev/null; then
    echo "WP-CLI could not be found. Please install it and retry."
    exit
fi

echo "${COLOR_YELLOW}Creating an admin user...${COLOR_DEFAULT}";

# Loop until it's set.
while [ -z "$USER_PASSWD" ]; do
    echo "Do you wish to to use 'admin' as password or a random generated one?";
    echo "[1] Use 'admin'";
    echo "[2] Use a random generated one";
    read input
    case $input in
        [1]* ) USER_PASSWD="admin";;
        [2]* ) USER_PASSWD="$(openssl rand -hex 32)";;
    esac
done

# Clear stored input.
unset input

# Check if 'admin' user exists and whether to delete it.
EXISTING_USER_ID=`wp user list --skip-themes --skip-plugins --fields=ID,user_login --format=csv | awk -F',' -v U="$USER_NAME" '$2==U {print $1}'`
if [ ! -z "$EXISTING_USER_ID" ]; then
  echo "\n${COLOR_RED}User '$USER_NAME' already exists. Would you like to delete it (y/n)?${COLOR_DEFAULT}";
  while [ -z "$DEL_USER" ]; do
    echo "Do you wish to to use 'admin' as password or a random generated one?";
    echo "[1] Use the current '$USER_NAME' user";
    echo "[2] Delete it and create a new one";
    echo "[3] Do nothing and quit. I'll check it myself.";
    read input
    case $input in
        [1]* )
          DEL_USER=1;
          ADMIN_USER_ID=$EXISTING_USER_ID;
          ;;
        [2]* )
          DEL_USER=2;
          DUMMY_USER="$(openssl rand -hex 32 | md5 | head -c 10;)";
          # Ugly parsing but wasted too much time on that one...
          DUMMY_USER_ID=`wp user create $DUMMY_USER "$DUMMY_USER@local.host" --user_pass=dummy --skip-themes --skip-plugins | awk -F. '{print $1}' | awk '{print $4}'`;

          echo "${COLOR_GREEN}A dummy was user created successfully to delete the rest freely.${COLOR_DEFAULT}";
          wp user delete $(wp user list --field=ID --exclude=$DUMMY_USER_ID --skip-themes --skip-plugins) --reassign=$DUMMY_USER_ID --skip-themes --skip-plugins &> /dev/null;

          echo "${COLOR_GREEN}Content moved to dummy user and creating new '$USER_NAME'...${COLOR_DEFAULT}";
          ADMIN_USER_ID=`wp user create $USER_NAME "$USER_NAME@local.host" --user_pass=$USER_PASSWD --skip-themes --skip-plugins | awk -F. '{print $1}' | awk '{print $4}'`;

          echo "${COLOR_GREEN}A new '$USER_NAME' user was created successfully to delete the rest freely.${COLOR_DEFAULT}";
          ;;
        [3]* ) DEL_USER=3;echo "${COLOR_BLUE}Ok.${COLOR_CYAN}Bye.${COLOR_DEFAULT}";exit;;
    esac
  done
else
  ADMIN_USER_ID=`wp user create $USER_NAME "$USER_NAME@local.host" --user_pass=$USER_PASSWD --skip-themes --skip-plugins | awk -F. '{print $1}' | awk '{print $4}'`;

  echo "${COLOR_GREEN}A new '$USER_NAME' user was created successfully to delete the rest freely.${COLOR_DEFAULT}";
fi

echo "${COLOR_YELLOW}Deleting users and reassigning content to '$USER_NAME'...${COLOR_DEFAULT}";
wp user delete $(wp user list --field=ID --exclude=$ADMIN_USER_ID --skip-themes --skip-plugins) --reassign=$ADMIN_USER_ID --skip-themes --skip-plugins &> /dev/null;

echo "${COLOR_GREEN}All done! Here's the current list of users:${COLOR_DEFAULT}";
wp user list --skip-themes --skip-plugins;
