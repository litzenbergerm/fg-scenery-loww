#!/bin/bash

export PNG_PATH=../data/textures/png_512
export ATLAS_DIR=/home/martin/_fghome_/Export

#cd $ATLAS_DIR
cd $PNG_PATH

for a in $ATLAS_DIR/*.atlas
do
    arg=
    
    while IFS= read -r f
    do
      arg="$f $arg"
    done < "$a"
    
    convert -append $arg "${a%.*}".png
    
done


echo "====================="
echo "done."
echo "====================="
