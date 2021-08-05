#!/bin/bash

## Make a mod template for openra based on https://github.com/OpenRA/OpenRAModSDK/wiki/Getting-Started 

## Get parameters 

echo -n "Mod type (cnc/ra/d2k): "
read mod_type
mod_type="${mod_type,,}"

[ "$mod_type" != "cnc" ] && [ "$mod_type" != "ra" ] && [ "$mod_type" != "d2k" ] && \
  echo "Mod type must be cnc, ra or d2k" && exit 1

echo -n "Enter mod short name: "
read short_name

echo -n "Enter mod full title: "
read mod_title

## Do stuff

function add_to_end_of_yaml_section() {
  #$1 section name
  #$2 what to add
  #$3 YAML filename

  tmpfile=`mktemp`
  awk -v secname="$1:" -v newcontent="$2" '
    BEGIN{active=0}
    index ($0, secname) {active=1}
    /^$/{if (active==1) {
          printf "%s\n", newcontent
          active=0
         }}
       { print }' "$3" > tmpfile
  mv tmpfile $3
}

function remove_project_from_sln() {
  #$1 the name of the project to remove
  #$2 .sln filename
  tmpfile=`mktemp`
  awk -v projname="\"$1\"" '
    BEGIN{foundproj=0}
    index ($0, projname) { foundproj=1 }
    !index ($0, projname) {
      if (foundproj==0) { print }
      foundproj=0
    }
  ' "$2" > $tmpfile
  mv $tmpfile "$2"
}

function change_mod_config_value() {
  #$1 the key to change the value for
  #$2 the new value
  #$3 mod.config
  sed -ri "s/^($1=\").*/\1$2\"/" $3
}

rm -rf mods/example OpenRA.Mods.Example

remove_project_from_sln "OpenRA.Mods.Example" "ExampleMod.sln"

mod_dir="mods/$short_name"
mkdir "$mod_dir"

engine_mod_dir="engine/mods/$mod_type"

cp "$engine_mod_dir/mod.yaml" "$mod_dir"
cp "$engine_mod_dir/icon.png" "$mod_dir"

sed -ri "s/(\s+Title:).*/\1 $mod_title/" "$mod_dir/mod.yaml"

touch "$mod_dir/rules.yaml" "$mod_dir/weapons.yaml"

add_to_end_of_yaml_section "Packages" "\t\$$short_name:$short_name" "$mod_dir/mod.yaml"
add_to_end_of_yaml_section "Rules" "\t$short_name|rules.yaml" "$mod_dir/mod.yaml"
add_to_end_of_yaml_section "Weapons" "\t$short_name|weapons.yaml" "$mod_dir/mod.yaml"

echo -e "ModCredits:" >> "$mod_dir/mod.yaml"
echo -e "\tModCreditsFile: $short_name|credits.txt" >> "$mod_dir/mod.yaml"
echo -e "\tModTabTitle: $mod_title" >> "$mod_dir/mod.yaml"

touch "$mod_dir/credits.txt"

change_mod_config_value "MOD_ID" "$short_name" mod.config
change_mod_config_value "PACKAGING_COPY_ENGINE_FILES" ".\/mods\/modcontent .\/mods\/$short_name" mod.config

## todo: populate PACKAGING_INSTALLER_NAME, PACKAGING_WEBSITE_URL, PACKAGING_AUTHORS,
##         PACKAGING_WINDOWS_LAUNCHER_NAME, PACKAGING_WINDOWS_INSTALL_DIR_NAME and
##         PACKAGING_WINDOWS_REGISTRY_KEY
