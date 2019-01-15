cd $(dirname ${BASH_SOURCE:-$0})

# 設定
URL="http://xa-kakeshita.local:8080"
PUBLIC_DIR="public_html"
WP_DIR=“/wp-xa-kakeshita "
WP_DIR="/wp-xa-kakeshita "
WP_CONTENT_DIR="/wp-content"
THEME_NAME=“xa-kakeshita”
DB_NAME=“xa-kakeshita_wp”
THEME_NAME="xa-kakeshita"
DB_NAME="xa-kakeshita_wp"
DB_USER=root
DB_PASS=password
DB_HOST=localhost

if [ ! -e "wp-cli.phar" ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
fi

if [ ! -e "${PUBLIC_DIR}${WP_DIR}/wp-load.php" ]; then
    php wp-cli.phar core download --locale=ja --path=./public_html${WP_DIR}
fi


if ! `mysql -h${DB_HOST} -p${DB_PASS} -u${DB_USER} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"` > /dev/null 2>&1 ; then
  echo "Connection failed."
  exit 2
fi

if [ ! -e "${PUBLIC_DIR}${WP_DIR}/wp-config.php" ]; then
    php wp-cli.phar core config --dbname=${DB_NAME} --dbuser=${DB_USER} --dbpass=${DB_PASS} --dbhost=${DB_HOST} --skip-salts --path=./public_html${WP_DIR} --extra-php <<PHP
define('AUTH_KEY',         'fPCVs5wRPt_M4cd6iQugKUkVWQAVaSfuJ6ArBXGsjw7kAfsuNswEr8PFK54P2VfU');
define('SECURE_AUTH_KEY',  'nBX9yQXfpGLBT-Ycc-TK_ifSuhtEd4TER4BKj6rw8eKSR7Mp6Nfap3dP9wQ8MPwS');
define('LOGGED_IN_KEY',    'Nbm59GGaMk9Cy_F_3gdxttnY_ZeFBwWw99LTan_ZubPWZ6L4r4RPJ6daDzFCpx3g');
define('NONCE_KEY',        'xa_ja7tV3fbsE8-sYCmEkGtPAZa4A5VMtnJ4ZsxbA5Tf4Mpuw5JuRKHEQ6GJbzr8');
define('AUTH_SALT',        'WRDfnBx82KDabd_TgfudNE_Md82SnzE-w_4jKcWcWjuRfABey355yFD-bViTVgG9');
define('SECURE_AUTH_SALT', 'EVmMcFaxc9hEsCPCChPXcbLaPjHMhrKRW_7mwJtw2uPfTGFbgjYRD_JXnWGDUij2');
define('LOGGED_IN_SALT',   '6V4ZHNHetJjDzGeDUHcnPGJ585TtQjdRXK_w4nRRW3-tKg8mxQUhcu4-nfpdbBwf');
define('NONCE_SALT',       'jzzHnUg7xMZnmfJNXpd2JriRPNDsBfyT3XT9nNrfCMxtZnTrh55aMM2YZHLj2YXQ');
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_SITEURL', '${URL}${WP_DIR}' );
define( 'WP_HOME', '${URL}' );
define( 'WP_CONTENT_DIR', dirname(__DIR__) . '${WP_CONTENT_DIR}' );
define( 'WP_CONTENT_URL', WP_HOME . '${WP_CONTENT_DIR}');
PHP
    
    php wp-cli.phar core install --path=./public_html${WP_DIR} --url=${URL} --title=${THEME_NAME} --admin_user=admin_xa-kakeshita --admin_email=xesys@xearts.jp


fi


# create theme
if [ ! -e "${PUBLIC_DIR}${WP_CONTENT_DIR}/themes/${THEME_NAME}" ]; then
    php wp-cli.phar  scaffold _s ${THEME_NAME} --theme_name="${THEME_NAME}" --author="xeArts" --path=./public_html${WP_DIR} --sassify
fi


# install plugins
for plugin in all-in-one-seo-pack custom-post-type-ui mw-wp-form simple-image-sizes password-protected google-sitemap-generator limit-login-attempts permalink-trailing-slash-fixer
do
    if [ ! -e "${PUBLIC_DIR}${WP_CONTENT_DIR}/plugins/${plugin}" ]; then
        php wp-cli.phar plugin install ${plugin} --path=./public_html${WP_DIR}
    fi
done



if [ ! -e "movefile.yml" ]; then
    cp Movefile.dist movefile.yml
    sed -i '' "s|\/path\/to\/project|${PWD}|g" movefile.yml
    sed -i '' "s|vhost: \"http://localhost\"|vhost: \"${URL}\"|g" movefile.yml
fi
