# NetworkManager owns Wi-Fi client policy in Saha images. Keep the BSP's
# firmware, antenna setup, and Bluetooth services, but do not install its
# standalone wpa_supplicant service or wlan0 systemd-networkd profile.
PACKAGECONFIG:remove = "standalone-wifi"
