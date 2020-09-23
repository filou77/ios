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
    
    # Asume the original file is in UTF-8
    utf8File="$file"
    
    # If not, create a new file in UTF-8
    if [ "$encoding" != "utf-8" ]; then
        utf8File="$file.utf8"
    
        # First convert the file in UTF8
        iconv --from-code="$encoding" --to-code=UTF-8 "$file" > "$utf8File" 
    fi
    
    ##################
    # Then adjust the file content
    # Here goes the real logic of that scritp, the rest is just plumbing ...
    #
    
    # For the lack of a better URL point to our default website
    sed --in-place 's/https:\/\/nextcloud.com\/migration/https:\/\/www.medicalcloud.fr/g' "$utf8File" 
    
    # All the user facing occurence of the Nextcloud word use that capitalization
    # Do not use case-insensitive match to not change the string keys that may contains the word "nextcloud" (in lower case)
    sed --in-place 's/Nextcloud/Medical Cloud/g' "$utf8File" 
    
    #
    ##################
    
    # If not UTF-8
    if [ "$encoding" != "utf-8" ]; then
        #Convert it back to the original encoding
        iconv --from-code=UTF-8 --to-code="$encoding" "$utf8File" > "$file" 
        
        # Cleanup the temp UTF-8 file
        rm "$utf8File" 
    fi
    
    echo " done."
done

# Restore PWD
cd $oldPWD
