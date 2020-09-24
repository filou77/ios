#!/bin/bash
#
# This script will look for the translations files and adjust all references to nextcloud
# It is more complex than it looks because all the translation files are not encoded in UTF-8 ...
#
# And other standard *nix tools (suc as sed) expects null terminated string and so does not works with UCS-2 (a subset of UTF-16)

# Stop on errors
set -e

# During dev
#set -x

oldPWD=$(pwd)
TRANSLATION_ROOT_FOLDER="iOSClient/Supporting Files"

# Move to the folder 
echo "Moving to: $TRANSLATION_ROOT_FOLDER"
cd "$TRANSLATION_ROOT_FOLDER"

for file in $(ls  *.lproj/Localizable.strings); do
    
    printf '%-50s' "Adjusting $file: "
    
    # Some files are in UTF-8, some are not. ¯\_(ツ)_/¯
    # In fact only the file in en.lproj is in UTF-8, all the other are in UCS-2LE (which is a strict subset of UTF-16LE)
    
    # Search for the encoding of the file
    encoding=$(file --mime "$file" | grep --only-matching "charset=[[:alnum:]-]*" | sed 's/charset=//' )
    
    # We need an file with a sure UTF-8 encoding
    utf8File="$file.utf8"

    # If needed, convert to UTF-8
    if [ "$encoding" != "utf-8" ]
    then
        iconv --from-code="$encoding" --to-code=UTF-8 "$file" > "$utf8File.0"
    else
        cp "$file" "$utf8File.0"
    fi
    
    ##################
    # Then adjust the file content
    # Here goes the real logic of that scritp, the rest is just plumbing ...
    # Also to not rely on the not very portable --in-place option of sed,
    # use temp files (that could also be usedull for debugging)
    #

    # For the lack of a better URL point to our default website
    cat "$utf8File.0" | sed 's/https:\/\/nextcloud.com\/migration/https:\/\/www.medicalcloud.fr/g' > "$utf8File.1"
    
    # All the user facing occurence of the Nextcloud word use that capitalization
    # Do not use case-insensitive match to not change the string keys that may contains the word "nextcloud" (in lower case)
    cat "$utf8File.1" | sed 's/Nextcloud/Medical Cloud/g' > "$utf8File.2"
    
    cp "$utf8File.2" "$utf8File.last"

    #
    ##################
    
    # If required, convert it back to the original encoding
    if [ "$encoding" != "utf-8" ]; then
        iconv --from-code=UTF-8 --to-code="$encoding" "$utf8File.last" > "$file"
    else
        cat "$utf8File.last" > "$file"
    fi
    
    # Cleanup the temp UTF-8 files
    rm "$utf8File".*

    echo " done."
done

# Restore PWD
cd $oldPWD

