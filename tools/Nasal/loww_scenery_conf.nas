var ERRS = 0;
var MINDIST = 25;
var PLACEMENT = "cycl"; #rand or cycl

var filein = getprop("/sim/fg-home") ~ '/Export/loww-airport-objects.csv';
var pathout = getprop("/sim/fg-home") ~ '/Export/';
var stgfile = "loww-out.stg";

# how to parse the CSV:
var LAT = "Y";
var LON = "X";
var TYP = "type";
#var TYP = "building";
var ORI = "ORI";

var obj = {
  RESIDENTIAL: 
    [
    "mid-eu-house-1.ac",
    "mid-eu-house-2.ac",
    "mid-eu-house-3.ac",
    "mid-eu-house-4.ac",
    "mid-eu-house-5.ac",
    "mid-eu-house-6.ac",
    ], 
  HOUSE: 
    [
    "mid-eu-house-1.ac",
    "mid-eu-house-2.ac",
    "mid-eu-house-3.ac",
    "mid-eu-house-4.ac",
    "mid-eu-house-5.ac",
    "mid-eu-house-6.ac",
    ], 
  YES: 
    [
    "mid-eu-house-1.ac",
    "mid-eu-house-2.ac",
    "mid-eu-house-3.ac",
    "mid-eu-house-4.ac",
    "mid-eu-house-5.ac",
    "mid-eu-house-6.ac",
    ], 
  SHED: 
    [
    "barn-1.ac",
    "barn-2.ac",
    "barn-2.ac",
    "barn-3.ac",
    ],
  FARM_AUXILIARY: 
    [
    "barn-1.ac",
    "barn-2.ac",
    "barn-2.ac",
    "barn-3.ac",
    ],  
  FARM: 
    [
    "barn-1.ac",
    "barn-2.ac",
    "barn-2.ac",
    "barn-4.ac",
    ],
  BARN: 
    [
    "barn-1.ac",
    "barn-2.ac",
    "barn-2.ac",
    "barn-4.ac",
    ],
  LP: 
    [
    "loww/loww-apronlamp.xml",
    ],
  AB: 
    [
    {model:"Scenery/Models/Airport/Jetway/jetway-ba.xml", model_ori:180.0, repeat:1, zoffset: 0},
    ],
  TA: 
    [
    "Scenery/Models/Airport/EDDP_DHL_Tank.xml",
    ],
  WS: 
    [
    "Scenery/Models/Airport/windsock.xml",
    ],
  WT: 
    [
    "windturbine_flash_mod.xml",
    ],
  RA: 
    [
    "Scenery/Models/Airport/surface_movenement_radar_lamp.xml",
    "Scenery/Models/Airport/radar_meteo.xml",
    ],
  AC: 
    [
    {model:"Scenery/Models/Aircraft/A320-iberia.ac", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/320austrian.xml", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/320austrian.xml", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/MD90_services.xml", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/320austrian.xml", model_ori:0.0, repeat:0, zoffset: 0},
    ],
  SAC: 
    [
    {model:"Scenery/Models/Aircraft/ERJ145_services.xml", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/MD90_services.xml", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/RJ70-ba.xml", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/atr42-iberia.xml", model_ori:0.0, repeat:0, zoffset: 3.77},
    {model:"Scenery/Models/Aircraft/atr42_500-airdolomiti.ac", model_ori:90.0, repeat:0, zoffset: 0},
    ],
  GAAC: 
    [
    {model:"Scenery/Models/Aircraft/bonanzae35yellow1.ac", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/C208Car-bluen642dg.ac", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/Citation-II-Type1.xml", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/falcon7xstrip1.ac", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/Cessna172_sky.xml", model_ori:180.0, repeat:0, zoffset: 0},
    ],
  CAC: 
    [
    {model:"Scenery/Models/Aircraft/A310_services.xml", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Aircraft/Boeing_767-300-dhl.ac", model_ori:90.0, repeat:0, zoffset: 0},
    ],
  CAB: 
    [
    {model:"Scenery/Models/Airport/caisses1.xml", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Airport/caisses2.xml", model_ori:90.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Airport/caisses_services.xml", model_ori:90.0, repeat:0, zoffset: 0},
    ],
  FIRE: 
    [
    {model:"Scenery/Models/Airport/Vehicle/ELW_Sprinter_215.ac", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Airport/Vehicle/Rosenbauer_FLF_Panther8x8.ac", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Airport/Vehicle/Rosenbauer_FLF_Panther8x8SWB.ac", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Airport/Vehicle/Rosenbauer_TLF_5500.ac", model_ori:0.0, repeat:0, zoffset: 0},
    {model:"Scenery/Models/Airport/Vehicle/Rosenbauer_FLF_VFAEG.ac", model_ori:0.0, repeat:0, zoffset: 0},
    ],
  PUSH: 
    [
    {model:"Scenery/Models/Airport/Pushback/Goldhofert.ac", model_ori:0.0, repeat:0, zoffset: 0},
    ],
    
};

# Use 3D city model

var USE_3DCITY = 0;
var CITY_RADIUS = 2500;

var modelpath = getprop("/sim/fg-home") ~ '/3dcity/';
var citycenters = getprop("/sim/fg-home") ~ '/Export/citycenters.csv';
var cityfile = "loww-city.ac";

# which of the objects shall be placed in one city model

var cityobj = 
    "mid-eu-house-1.ac"~
    "mid-eu-house-2.ac"~
    "mid-eu-house-3.ac"~
    "mid-eu-house-4.ac"~
    "mid-eu-house-5.ac"~
    "mid-eu-house-6.ac"~
    "barn-1.ac"~
    "barn-2.ac"~    
    "barn-3.ac"~
    "barn-4.ac";
    
var citymodels = {};

#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/object_placement.nas");
#object_placement.do( "/Aircraft/working/loww_scenery_conf.nas" );
