# this script splits up the whole LOWW ac3d file into building groups for more
# efficient loading. for each group the COG is calculated and a corresponding
# line for the .stg file is generated. An XML for activiting night textures is
# automatically generated together with the .ac file.
# the reference point used for all LOWW buildings is N48.117921, E016.560051

# call with this lines from fg nasal console:

#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/object_splitup.nas");
#object_splitup.do( getprop("/sim/fg-home") ~ "/Export/loww-xplane-buildings.ac", 48.117921, 16.560051 );

io.include("/fghome/Nasal/common-geo.nas");

var JOINALL = 1;

# bounding box definition for building groups
# bb = l r u d
# from W to E

var groups = [
    {name: "loww-ga", 
       bb: [15.0, 16.540, 49.0, 48.123]
    },
    {name:"loww-hangars", 
       bb: [16.540, 16.549, 48.200, 48.116]
    },
    {name:"loww-cargo", 
       bb: [16.549, 16.5565, 48.200, 48.121]
    },
    {name: "loww-north" ,
        bb: [16.556, 16.570, 49.0, 48.125]
    },
    {name: "loww-businesspark",
       bb: [16.5565, 16.567, 48.125, 48.121]
    },
    {name:"loww-terminals",
       bb: [16.5555, 16.570,  48.121, 48.116]
    },
    {name:"loww-tank",
       bb: [16.567, 16.574, 48.124, 48.121] 
    },
    {name: "loww-east",
      bb: [16.570, 16.581, 49.0, 48.124]
    },
    {name: "loww-fire-east",
      bb: [16.570, 16.581, 48.116, 48.112]
    },
    {name: "loww-south",
      bb: [16.556, 16.570, 48.116, 48.0]
    },
    
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
    
        var cog = mainmodel.centroid(-1, i); # in meters
        var bb = mainmodel.bbox(i);
        debug.dump(bb);
        
        #find the cog position of this object in wgs84
        
        var thispos = Dxy2wgs(refpoint, ac2bl(cog) ); # in wgs84
        print("testing... ", mainmodel.obj[i].name );
        thispos.dump(); 
            
        foreach(var g; groups) {
            if (geoinside(thispos, g.bb)) {
                print("splitup: add ", mainmodel.obj[i].name );
                g.cog = add3d( g.cog, cog);    # add to sum cog of group, meters
                
                g.model.addac(mainmodel, i);
                append(g.objlist, { 
                      name: string.replace(mainmodel.obj[i].name, '"', "") , 
                      tex:  string.replace(mainmodel.obj[i].texture , '"', "") ,
                      bb:   bb,
                      pos:  [thispos.lat(), thispos.lon(), thispos.alt()],
                      cog:  cog
                     }     
                );
            }    
        }
    }
   
    # write all groups' ac model files   
    var f1 = io.open(pathout ~ "splitobjects.stg","w");
   
    foreach(var g; groups) {
        n=size(g.model.obj);
        if (n>0) {
            g.cog = [g.cog[0]/n, g.cog[1]/n, g.cog[2]/n]; # cog of group, meters
            g.refpoint = Dxy2wgs(refpoint, ac2bl(g.cog) ); # cog of group, in wgs
            
            #shift all buildings by -cog (to cog)
            for(var i=0; i<n; i+=1) {
                g.model.recentercog(i);
                g.model.transobj(sub3d( [0,0,0], g.cog ), i);
                
            }
            
            if (JOINALL) {
                 #combine all buildings into one model
                 var atlas = g.model.joinall(g.name);
                 g.atlas = atlas;
            }
            
            #debug.dump(g.cog);
            g.model.save(pathout~g.name~".ac",2);
            
            outline = "OBJECT_STATIC loww/"~ g.name~".xml "~ fix(g.refpoint.lon(),8) ~" "~ fix(g.refpoint.lat(),8) ~" "~ fix(g.refpoint.alt(),2) ~" 0.0";
            io.write(f1, outline~"\n");
        }
        
        # add2stg(stg, refpoint[j], outline);
   }
   io.close(f1);
   
   # write all xml files for night textures change
   
   foreach (var g; groups) {   
       
      var f = io.open(pathout ~ g.name ~ ".xml","w");
      io.write(f, '<?xml version="1.0"?>'); 
      io.write(f, "\n<PropertyList>\n\n" ); 
      
      io.write(f, "<path>"~g.name~".ac</path>\n" ); 
      
      if (JOINALL) {
          
        # texture-atlas file.
        io.write(f, animation_preamble ); 
        io.write(f, "  <object-name>"~ g.name ~"</object-name>\n" ); 
        io.write(f, "  <texture>"~ makelit( g.name ~ ".png" ) ~"</texture>\n"); 
        io.write(f, animation_post ); 

        # make the list of texture files, that go into the texture atlas.
        var a = io.open(pathout ~ g.name ~ ".atlas", "w");
        foreach(var u; g.atlas)
            io.write(a, ((u == '""') ? "NULL" : string.replace(u, '"', "")) ~ "\n"); 
        io.close(a);

      } else {

        foreach(var u; g.objlist) {            
            io.write(f, "<!-- cg-pos:"~u.cog[0]~" " ~u.cog[1]~ " " ~u.cog[2]~ ", bottom(z):" ~ u.bb.min[1] ~ " -->" ); 
            io.write(f, animation_preamble ); 
            io.write(f, "  <object-name>"~ u.name ~"</object-name>\n" ); 
            io.write(f, "  <texture>"~ makelit( u.tex ) ~"</texture>\n"); 
            io.write(f, animation_post ); 
        }
        
      }
      io.write(f, "</PropertyList>" ); 
      io.close(f);
   }

   mainmodel = nil;
   print("done.");

#   print(total, " objects placed (", total/l*100, "%, in city: ", incity/l*100 ,"%). Too close: ", tooclose, ". unknown: ", unknown );
};
