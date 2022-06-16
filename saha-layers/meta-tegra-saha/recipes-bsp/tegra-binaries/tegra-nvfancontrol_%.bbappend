pkg_postinst:${PN}:tegra() {
  sed -i "s/FAN_DEFAULT_PROFILE quiet/FAN_DEFAULT_PROFILE cool/g" $D/etc/nvfancontrol.conf
}
