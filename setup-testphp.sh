#!/bin/sh

cd $(dirname ${BASH_SOURCE:-$0})


if [ ! -e ".env" ]; then
    cp ./.env.dist ./.env
fi

. ./.env


echo "------ setup composer"
if [ ! -e "composer.phar" ]; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
fi

php composer.phar install


echo "------ setup valet"
./vendor/bin/valet install

cd ${PUBLIC_DIR}

../vendor/bin/valet park
../vendor/bin/valet link ${APP_NAME}
cd ../



 echo "------ wp-cli"
 if [ ! -e "wp-cli.phar" ]; then
     curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
 fi

 if [ ! -e "${PUBLIC_DIR}${WP_DIR}/wp-load.php" ]; then
     php wp-cli.phar core download --locale=ja --path=${PUBLIC_DIR}${WP_DIR}
 fi


if ! `mysql -h${DB_HOST} -p${DB_PASS} -u${DB_USER} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"` > /dev/null 2>&1 ; then
  echo "Connection failed."
  exit 2
fi

 if [ ! -e "${PUBLIC_DIR}${WP_DIR}/wp-config.php" ]; then
     php wp-cli.phar core config --dbname=${DB_NAME} --dbuser=${DB_USER} --dbpass=${DB_PASS} --dbhost=${DB_HOST} --skip-salts --path=${PUBLIC_DIR}${WP_DIR} --extra-php <<PHP


 define('AUTH_KEY',         '${AUTH_KEY}');
 define('SECURE_AUTH_KEY',  '${SECURE_AUTH_KEY}');
 define('LOGGED_IN_KEY',    '${LOGGED_IN_KEY}');
 define('NONCE_KEY',        '${NONCE_KEY}');
 define('AUTH_SALT',        '${AUTH_SALT}');
 define('SECURE_AUTH_SALT', '${SECURE_AUTH_SALT}');
 define('LOGGED_IN_SALT',   '${LOGGED_IN_SALT}');
 define('NONCE_SALT',       '${NONCE_SALT}');


 define( 'WP_DEBUG', true );
 define( 'WP_DEBUG_LOG', true );


 define( 'WP_SITEURL', '${URL}${WP_DIR}' );
 define( 'WP_HOME', '${URL}' );

 define( 'WP_CONTENT_DIR', dirname(__DIR__) . '${WP_CONTENT_DIR}' );
 define( 'WP_CONTENT_URL', WP_HOME . '${WP_CONTENT_DIR}');


# PHP

     php wp-cli.phar core install --path=${PUBLIC_DIR}${WP_DIR} --url=${URL} --title=${THEME_NAME} --admin_user=${WP_ADMIN} --admin_email=xesys@xearts.jp


# fi


# #install languages
 php wp-cli.phar language core install ja --path=${PUBLIC_DIR}${WP_DIR} --activate


# # create theme
 if [ ! -e "${PUBLIC_DIR}${WP_CONTENT_DIR}/themes/${THEME_NAME}" ]; then
     php wp-cli.phar  scaffold _s ${THEME_NAME} --theme_name="${THEME_NAME}" --author="xeArts" --path=${PUBLIC_DIR}${WP_DIR} --sassify
 fi
 php wp-cli.phar theme activate ${THEME_NAME} --path=${PUBLIC_DIR}${WP_DIR}


# # install plugins
 for plugin in all-in-one-seo-pack custom-post-type-ui mw-wp-form simple-image-sizes password-protected google-sitemap-generator limit-login-attempts permalink-trailing-slash-fixer
 do
     if [ ! -e "${PUBLIC_DIR}${WP_CONTENT_DIR}/plugins/${plugin}" ]; then
         php wp-cli.phar plugin install ${plugin} --path=${PUBLIC_DIR}${WP_DIR}
     fi
 done




# echo "------ setup WordMove"
 if [ ! -e "movefile.yml" ]; then
     cp Movefile.dist movefile.yml
     sed -i '' "s|\/path\/to\/project|${PWD}|g" movefile.yml
     sed -i '' "s|vhost: \"http://localhost\"|vhost: \"${URL}\"|g" movefile.yml
 fi
