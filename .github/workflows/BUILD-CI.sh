set -ex

# https://docs.aws.amazon.com/freertos/latest/userguide/getting_started_cypress_psoc64.html

OPTIMIZE_SUBMODULES=0

SOURCE_REPO=https://github.com/aws/amazon-freertos
REPO_DIR=amazon-freertos

git clone -q $SOURCE_REPO $REPO_DIR

cd $REPO_DIR

# Allow to override amazon-freertos's revision/branch to build against
# (e.g., to build against a particular PR, not merged yet).
if [ -f ../freertos-pkcs11-psa/amazon-freertos.rev ]; then
    REV=$(cat ../freertos-pkcs11-psa/amazon-freertos.rev)
    git fetch origin $REV:$REV || true
    git checkout $REV
fi

if [ $OPTIMIZE_SUBMODULES -eq 0 ]; then
    git submodule update --recursive --init
else
    git submodule update --recursive --init \
    freertos_kernel \
    libraries/coreHTTP \
    libraries/coreJSON \
    libraries/coreMQTT \
    libraries/device_defender_for_aws \
    libraries/device_shadow_for_aws_iot_embedded_sdk \
    libraries/jobs_for_aws \
    libraries/3rdparty/lwip \
    libraries/3rdparty/mbedtls \
    libraries/3rdparty/pkcs11 \
    libraries/abstractions/pkcs11/corePKCS11
fi

#    libraries/abstractions/pkcs11/psa \

rm -rf libraries/abstractions/pkcs11/psa

#mv ../freertos-pkcs11-psa libraries/abstractions/pkcs11/psa
ln -s $PWD/../freertos-pkcs11-psa libraries/abstractions/pkcs11/psa

ls -l libraries/abstractions/pkcs11
ls -l libraries/abstractions/pkcs11/psa/

# Revert doesn't go thru completely due to some submodule foo, but the
# needed files are put into the working tree, so we just ignore error.
git revert 287ed79eb6137443133d2a7200bc5591c02a8973 || true

if [ -d .venv ]; then
    . .venv/bin/activate
else
    python3 -m venv .venv
    . .venv/bin/activate
    python3 -m pip install cysecuretools
fi

which cysecuretools
#cysecuretools version


cd projects/cypress/CY8CKIT_064S0S2_4343W/mtb/aws_demos
rm -rf build
#mkdir -p build
#cd build

cmake -DVENDOR=cypress -DBOARD=CY8CKIT_064S0S2_4343W -DCOMPILER=arm-gcc -DBUILD_CLONE_SUBMODULES=OFF \
    -S ../../../../.. -B build

cmake --build build

ls -l build/*.hex

git submodule status
