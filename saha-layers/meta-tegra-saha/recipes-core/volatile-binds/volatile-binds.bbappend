# For Mender builds, remove /var/lib from the list
VOLATILE_BINDS:tegra-saha = "\
    /var/volatile/cache /var/cache\n\
    /var/volatile/spool /var/spool\n\
    /var/volatile/srv /srv\n\
"
