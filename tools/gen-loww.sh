#!/bin/bash

export LD_LIBRARY_PATH='/home/martin/fgbuild/install/simgear/lib'"${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH}"
export TG_PATH=/home/martin/fgbuild/install/terragear/bin

rm -r ./work/Shared/*

start=`date +%s`

if [ $1 == "all" ]; then

  echo "====================="
  echo "clean workspace.."
  echo "====================="

  rm -r ./work/SRTM-1/*

  echo "====================="
  echo "DEM data processing.."
  echo "====================="

  $TG_PATH/gdalchop ./work/SRTM-1 ./data/SRTM-1/*.hgt

  $TG_PATH/terrafit --minnodes 100 --maxnodes 10000 -e 5 --force ./work/SRTM-1

fi

  echo "====================="
  echo "airport data processing.."
  echo "====================="
  
  rm -r ./work/AirportArea/*
  rm -r ./work/AirportObj/*

  $TG_PATH/genapts850 --input=./data/airports/LOWW.apt.dat --work=./work --dem-path=./data/SRTM-1


echo "====================="
echo "landclass data processing.."
echo "====================="

awk 'BEGIN { ORS=" " }; { if ($1 !~ /["#"]/) system("rm -r ./work/"$1"/*") }' ./materials.txt
awk 'BEGIN { ORS=" " }; { if ($1 !~ /["#"]/) system("echo --"$1",w="$3" && $TG_PATH/ogr-decode --line-width "$3" --max-segment 10 --area-type "$1"  work/"$1" data/shapefiles/"$2) }' ./materials.txt
#/home/martin/fgbuild/install/terragear/bin/ogr-decode --line-width 1 --max-segment 10 --area-type Road ./work/Road ./data/shapefiles/osm_secondary

echo "====================="
echo "compiling scenery"
echo "====================="

# use all lines of material not starting with #

awk 'BEGIN { ORS=" " }; { if ($1 !~ /["#"]/) print $1 }' ./materials.txt | xargs \
  $TG_PATH/tg-construct \
  --threads=8 --ignore-landmass --work-dir=./work \
  --output-dir=./output/Scenery/Terrain \
  --min-lon=16.00 --max-lon=17.99 --min-lat=47.00 --max-lat=48.99 \
  SRTM-1 AirportArea AirportObj $1

end=`date +%s`
echo execution time `expr $end / 60 - $start / 60` min.

echo "====================="
echo "done."
echo "====================="
