#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/object_splitup.nas");
#object_splitup.do( getprop("/sim/fg-home") ~ "/Export/loww-xplane-buildings.ac", 48.117921, 16.560051 );

io.include("/fghome/Nasal/common-geo.nas");

# bb = l r u d
# from W to E

var groups = [
    {name: "loww-ga", 
       bb: [15.0, 16.540, 49.0, 48.123]
    },
    
    {name: "loww-north" ,
        bb: [16.540, 16.556, 49.0, 48.123]
    },
    {name:"loww-hangars", 
       bb: [16.540, 16.556, 48.123, 48.116]
    },
    
    {name: "loww-businesspark",
       bb: [16.556, 16.570, 49.0, 48.123]
    },
    {name:"loww-terminals",
       bb: [16.556, 16.570,  48.123, 48.116]
    },
    
    {name:"loww-tank",
       bb: [16.570, 17.0, 49.0, 48.123] 
    },
    {name: "loww-east",
      bb: [16.570, 17.0, 48.123, 48.0]
    },

    {name: "loww-south" ,
        bb: [15.0, 16.570, 48.116, 48.0]
    }
];

var pathout=getprop("/sim/fg-home") ~ "/Export/";

var animation_preamble = "<animation>\n  <type>material</type>\n";
var animation_post = "  <condition>\n    <greater-than>\n    <property>/sim/time/sun-angle-rad</property>\n" ~
    "    <value>1.57</value>\n    </greater-than>\n  </condition>\n  <emission>\n     <red>1</red><green>1</green><blue>1</blue>\n  </emission>\n" ~
    "</animation>\n";


var makelit = func (fn) {
  return string.replace(fn, ".png", "_LIT.png");
};

var do = func (fn, reflat=nil, reflon=nil) { 
    #io.include( conf );

    mainmodel = libac3d.Ac3d.new(fn);
    var l = size(mainmodel.obj);
    print("splitup: ", l, " objects in file.");
    
    var refpoint = geo.Coord.new();
    
    if (reflat==nil or reflon==nil) {
        die("splitup: no refpoint error");
    }
    
    var e = geo.elevation(reflat, reflon);    
    refpoint.set_latlon(reflat, reflon, e);
    foreach(var g; groups) {
        g["model"]=libac3d.Ac3d.new();
        g["refpoint"]=geo.Coord.new();
        g["objlist"]= [];
        g["cog"]= [0,0,0];
        
    }    
    
    var modelori = 0;
    var thisobj = nil;
    var outline = "";
    var total = 0;
    var tooclose = 0;
    var unknown = 0;
    var incity = 0;
    var objsel = 0;
    var e = 0;
    var objtype = "OBJECT_STATIC";
    var lat = 0;
    var lon = 0;
        
    # loop through all objects
    for (var i=0; i < l; i+=1) {
    
        var cog = mainmodel.centroid(-1, i);
        var thispos = Dxy2wgs(refpoint, ac2bl(cog) );
        print("testing... ", mainmodel.obj[i].name );
        thispos.dump(); 
            
        foreach(var g; groups) {
            if (geoinside(thispos, g.bb)) {
                print("splitup: add ", mainmodel.obj[i].name );
                g.cog = add3d( g.cog, cog);
                
                g.model.addac(mainmodel, i);
                append(g.objlist, [ 
                      string.replace(mainmodel.obj[i].name, '"', ""), 
                      string.replace(mainmodel.obj[i].texture , '"', "")
                      ]
                          
                    );
            }    
        }
    }
   
    # write all groups' ac model files   
       
    foreach(var g; groups) {
        n=size(g.model.obj);
        if (n>0) {
            g.cog = [g.cog[0]/n, g.cog[1]/n, g.cog[2]/n]; 
            g.refpoint = Dxy2wgs(refpoint, ac2bl(g.cog) );
            
            #shift all buildings by -cog (to cog)
            for(var i=0; i<n; i+=1)
                g.model.transobj(sub3d( [0,0,0],g.cog ), i);
            
            #debug.dump(g.cog);
            g.model.save(pathout~g.name~".ac",2);
            
            outline = "OBJECT_STATIC loww/"~ g.name~".ac "~ g.refpoint.lon() ~" "~ g.refpoint.lat() ~" "~ g.refpoint.alt() ~" 0.0";
            print(outline);
        }
        
        # add2stg(stg, refpoint[j], outline);
    }
   
   # write all xml files for night textures change
   
   foreach (var g; groups) {   
       
      var f = io.open(pathout ~ g.name ~ ".xml","w");
      io.write(f, '<?xml version="1.0"?>'); 
      io.write(f, "\n<PropertyList>\n\n" ); 
      
      io.write(f, "<path>"~g.name~".ac</path>\n" ); 
      
      foreach(var u; g.objlist) {
        io.write(f, animation_preamble ); 
        io.write(f, "  <object-name>"~u[0]~"</object-name>\n" ); 
        io.write(f, "  <texture>"~ makelit( u[1] ) ~"</texture>\n"); 
        io.write(f, animation_post ); 
      }
      io.write(f, "</PropertyList>" ); 
      io.close(f);
   }

   mainmodel = nil;
   print("done.");

#   print(total, " objects placed (", total/l*100, "%, in city: ", incity/l*100 ,"%). Too close: ", tooclose, ". unknown: ", unknown );
};
