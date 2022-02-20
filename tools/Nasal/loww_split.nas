
##############################################################

# the reference point used for all LOWW buildings is N48.117921, E016.560051

var JOINALL = 1;
var ALIGN2GROUND = 0;
var OBJSUB = "loww/";
var reflat = 48.117921;
var reflon = 16.560051;
var fn = getprop("/sim/fg-home") ~ "/Export/loww-xplane.ac";

##############################################################

var gpltxt = "\n\n<!-- LOWW airport scenery model for the Flightgear flight simulator.\n\nThis program is free software: you can redistribute it and/or modify it under \nthe terms of the GNU General Public License as published by the Free Software Foundation, \neither version 2 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT \nANY WARRANTY; without even the implied warranty of MERCHANTABILITY \nor FITNESS FOR A PARTICULAR PURPOSE. See the GNU General \nPublic License for more details.\n\nCredits: Original X Plane authors wuseldusel, danielman, Patrik W. and oe3gsu.\nConverted for Flightgear by powoflight.\nModel mesh optimization by M.Litzenberger (litzi on forum).\n-->\n\n";

# bounding box definition for building groups
# bb = l r u d
# from W to E

var groups = [
    {name: "loww-vds-gantry-s", 
       obj: ["vds.001","vds.002","vds.003","vds.004","vds.005"]
    },
    {name: "loww-ga", 
       bb: [15.0, 16.540, 49.0, 48.123]
    },
    {name:"loww-hangars", 
       bb: [16.540, 16.549, 48.200, 48.116]
    },
    {name:"loww-cargo-west", 
       bb: [16.549, 16.5535, 48.200, 48.121]
    },
    {name:"loww-cargo-east", 
       bb: [16.5535, 16.5565, 48.200, 48.121]
    },
    {name: "loww-north" ,
        bb: [16.556, 16.570, 49.0, 48.125]
    },
    {name: "loww-businesspark-north",
       bb: [16.5565, 16.567, 48.125, 48.12249]
    },
    {name: "loww-businesspark-south",
       bb: [16.5565, 16.567, 48.12249, 48.121]
    },
    {name:"loww-terminals-west",
       bb: [16.5555, 16.5621, 48.121, 48.116]
    },
    {name:"loww-terminals-ctr",
       bb: [16.5621, 16.565377, 48.121, 48.116]
    },
    {name:"loww-terminals-east",
       bb: [16.565377, 16.574, 48.1214, 48.116]
    },
    {name:"loww-tank",
       bb: [16.567, 16.574, 48.124, 48.121] 
    },
    {name: "loww-fire-east",
      bb: [16.570, 16.581, 48.116, 48.112]
    },
    {name: "loww-south",
      bb: [16.556, 16.570, 48.116, 48.0]
    }    
];
