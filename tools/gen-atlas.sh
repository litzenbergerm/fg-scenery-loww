#!/bin/bash

export PNG_PATH=../data/textures/png_512
export ATLAS_DIR=/home/martin/_fghome_/Export

#cd $ATLAS_DIR
cd $PNG_PATH

for a in $ATLAS_DIR/*.atlas
do
    arg=
    argL=
    
    while IFS= read -r f
    do
      arg="$f $arg"
      argL="${f%.*}_LIT.png $argL"
    done < "$a"
    
    convert -append $arg "${a%.*}".png    
    convert -append $argL "${a%.*}"_LIT.png
    
done

echo "====================="
echo "done."
echo "====================="
