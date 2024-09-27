#!/usr/bin/env bash
# set script as executable: chmod +x bbpm.sh
# put this line into .bashrc: alias bbpm=<path/to/script>/bbpm.sh
# usage: bbpm install mtr

PACKAGE_LIST=(mtr)
PACKAGE_SOURCES=(git@github.com:traviscross/mtr.git)
COMMAND_LIST=(install)
CURRENT_DIR=$PWD
COMMAND=$1
PACKAGE_NAME=$2
PACKAGE_VERSION=1.0.0
NOW_DATE="$(date -R)"
REST_API_URL='https://go.getblock.io/'
ACCESS_TOKEN='700133af6dbb40f98fb9e569c7edd556'

# checking if command is correct
if [[ -z "$COMMAND" ]]; then
    echo -e "\e[31m Command is not specified\e[0m "
    exit
fi

ALLOWED_COMMAND=
for cmd in "${COMMAND_LIST[@]}"; do
    if [[ $cmd = "$COMMAND" ]]; then
        ALLOWED_COMMAND="$cmd"
        break
    fi
done

if [[ -z "$ALLOWED_COMMAND" ]]; then
    echo -e "\e[31m Undefined command '$COMMAND' \e[0m"
    exit
fi

# checking if package exists in list
if [[ -z "$PACKAGE_NAME"  ]]; then
    echo -e '\e[31m Package is not specified \e[0m'
    exit
fi

ALLOWED_PACKAGE_INDEX=
for pkg in ${!PACKAGE_LIST[@]}; do
    if [[ "${PACKAGE_LIST[$pkg]}" = "$PACKAGE_NAME" ]]; then
        ALLOWED_PACKAGE_INDEX="$pkg"
        break
    fi
done

if [[ ! $ALLOWED_PACKAGE_INDEX ]]; then
    echo -e "\e[31m Undefined package '$PACKAGE_NAME' \e[0m"
    exit
fi    

SOURCE_CODE_URL="${PACKAGE_SOURCES[$ALLOWED_PACKAGE_INDEX]}"
CODE_DEST="$HOME/$PACKAGE_NAME/";

# cloning from git repo
echo -e '\e[1;34m Package downloading... \e[0m'
git clone -q $SOURCE_CODE_URL $CODE_DEST

# source code directory does not exist
if [[ ! -d $CODE_DEST ]]; then
    echo -e '\e[31m Package download error \e[0m'
    exit
fi

cd $CODE_DEST
SOURCE_CODE_HASH="$(git rev-parse --verify HEAD)"

# creating package's metadata files
mkdir debian
cd debian
echo "Source: $PACKAGE_NAME
Section: Devel
Priority: optional
Maintainer: John Doe <john@doe.com>
Build-Depends: debhelper (>= 9)

Package: $PACKAGE_NAME
Architecture: all
Description: $PACKAGE_NAME package" > ./control

echo "$PACKAGE_NAME ($PACKAGE_VERSION) stretch; urgency=medium
  * Initial packaging work with dpkg-buildpackage.
 -- John Doe <john@doe.com> $NOW_DATE" > ./changelog

echo 9 > ./compat

echo "#!/usr/bin/make -f

clean:
	@# Do nothing
build:
	@# Do nothing
binary:
	dh_gencontrol
	dh_builddeb" > ./rules

echo -e '\e[1;34m Building package... \e[0m'

cd ..
dpkg-buildpackage -b -uc -us

cd ..
DEB_PACKAGE_FILE="$(ls . | grep *.deb)"
DEB_PACKAGE_HASH="$(sha1sum $DEB_PACKAGE_FILE | cut -d " " -f 1)"

rm -rf "$CODE_DEST"

echo -e '\e[1;32m Success! \e[0m'