# Keep upstream's revision, license, blob selection and deploy contract. The
# ZERO 3W needs two small blobs, not the history of every supported Rockchip.
SAHA_RKBIN_URL = "https://raw.githubusercontent.com/rockchip-linux/rkbin/${SRCREV}"
SRC_URI:radxa-zero-3w = " \
    ${SAHA_RKBIN_URL}/LICENSE;name=license;subdir=${BP};downloadfilename=rkbin-${SRCREV}-LICENSE \
    ${SAHA_RKBIN_URL}/${RKBIN_BINDIR}${RKBIN_BINFILE};name=firmware;subdir=${BP}/${RKBIN_BINDIR};downloadfilename=rkbin-${SRCREV}-${RKBIN_BINFILE} \
"
SRC_URI[license.sha256sum] = "d2765124a2c24d71aba3cbc6cdd6975a5a297821264eb6c26378a4c16cd16e92"
S:radxa-zero-3w = "${UNPACKDIR}/${BP}"

# downloadfilename isolates the shared cache; restore upstream source names
# inside this recipe's unpack directory for license checks and do_deploy.
python saha_stage_rkbin_inputs() {
    if d.getVar("MACHINE") != "radxa-zero-3w":
        return
    import os
    source = d.getVar("S")
    revision = d.getVar("SRCREV")
    for relative in ("LICENSE", d.getVar("RKBIN_BINDIR") + d.getVar("RKBIN_BINFILE")):
        parent, name = os.path.split(relative)
        directory = os.path.join(source, parent)
        os.rename(os.path.join(directory, "rkbin-" + revision + "-" + name),
                  os.path.join(directory, name))
}
do_unpack[postfuncs] += "saha_stage_rkbin_inputs"
