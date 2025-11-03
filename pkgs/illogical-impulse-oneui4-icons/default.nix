{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "illogical-impulse-oneui4-icons";
  version = "unstable-2024-05-07";

  src = fetchFromGitHub {
    owner = "end-4";
    repo = "OneUI4-Icons";
    rev = "693095d45c67e6b48a9873e36af6283f05080e66";
    sha256 = "sha256-VWgITEJQFbPqIbiGDfDeD0R74y9tCKEfjO/M/tcO94M=";
  };

  patchPhase = ''
    # Remove broken symlinks
    find . -xtype l -delete

    # Fix index.theme files to add missing directory sections
    for theme_dir in OneUI OneUI-dark OneUI-light; do
      if [ -f "$theme_dir/index.theme" ]; then
        # Change inheritance from hicolor to Adwaita for better icon coverage
        sed -i 's/Inherits=hicolor/Inherits=Adwaita,hicolor/' "$theme_dir/index.theme"

        # Fix duplicate [16@2x/devices] that should be [22@2x/devices]
        sed -i '285,289s/\[16@2x\/devices\]/[22@2x\/devices]/' "$theme_dir/index.theme"

        # Add missing directory sections at the end of the file
        cat >> "$theme_dir/index.theme" <<'EOF'

# Missing sections for directories without size fields
[256/applets]
Context=Status
Size=256
Type=Fixed

[16@2x/emblems]
Context=Emblems
Scale=2
Size=16
Type=Fixed

[22@2x/emblems]
Context=Emblems
Scale=2
Size=22
Type=Fixed

[256@2x/applets]
Context=Status
Scale=2
Size=256
Type=Fixed
EOF
      fi
    done
  '';

  installPhase = ''
    install -d $out/share/icons
    cp -dr --no-preserve=mode OneUI{,-dark,-light} $out/share/icons/
  '';

  meta = {
    description = "A fork of mjkim0727/OneUI4-Icons for illogical-impulse dotfiles.";
    homepage = "https://github.com/end-4/OneUI4-Icons";
    license = lib.licenses.gpl3;
  };
}
