#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

###############
# Define user #
###############

PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

###################
# Create function #
###################

change_folders () {
  CONFIGLOCATION=$1
  ORIGINALLOCATION=$2
  TYPE=$3
  
    # Inform
    bashio::log.info "Setting $TYPE to $CONFIGLOCATION"

    # Modify files
    echo "Adapting files"
    grep -rl "$ORIGINALLOCATION" /etc/cont-init.d | xargs sed -i "s|$ORIGINALLOCATION|$CONFIGLOCATION|g"
    grep -rl "$ORIGINALLOCATION" /etc/services.d | xargs sed -i "s|$ORIGINALLOCATION|$CONFIGLOCATION|g"
    sed -i "s=$ORIGINALLOCATION=$CONFIGLOCATION=g" /etc/cont-init.d/10-adduser
    sed -i "s=$ORIGINALLOCATION=$CONFIGLOCATION=g" /defaults/*
    
    # Adapt sync.conf
      for FILE in "$ORIGINALLOCATION/sync.conf" "$CONFIGLOCATION/sync.conf" "/defaults/sync.conf"; do
          if [ "$TYPE" = "config_location" ]; then 
               [ -f "$FILE" ] && sed "s|$(jq -r .storage_path "$FILE")|$CONFIGLOCATION/|g" "$FILE"
          fi
          if [ "$TYPE" = "data_location" ]; then
                    [ -f "$FILE" ] && sed "s|$(jq -r .directory_root "$FILE")|$CONFIGLOCATION/|g" "$FILE"
                    [ -f "$FILE" ] && sed "s|$(jq -r .files_default_path "$FILE")|$CONFIGLOCATION/downloads|g" "$FILE"
          fi
      done

    # Create folders
    echo "Checking if folders exist"
    for FOLDER in "$CONFIGLOCATION" "$CONFIGLOCATION"/folders "$CONFIGLOCATION"/mounted_folders "$CONFIGLOCATION"/downloads; do
       [ ! -d "$FOLDER" ] && echo "Creating $FOLDER" && mkdir -p "$FOLDER"
    done
    
    # Set permissions
    echo "Setting ownership to $PUID:$PGID"
    chown -R "$PUID":"$PGID" "$CONFIGLOCATION"
    
    # Transfer files
    if [ -d "$ORIGINALLOCATION" ]; then
      echo "Files were existing in $ORIGINALLOCATION, they will be moved to $CONFIGLOCATION"
      mv "$ORIGINALLOCATION"/* "$CONFIGLOCATION"/
      rmdir "$ORIGINALLOCATION"
    fi
}

########################
# Change data location #
########################

# Adapt files
change_folders "$(bashio::config 'config_location')" "/share/resiliosync_config" "config_location"
change_folders "$(bashio::config 'data_location')" "/share/resiliosync" "data_location"
