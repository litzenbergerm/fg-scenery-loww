#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/object_splitup.nas");
#object_splitup.do( getprop("/sim/fg-home") ~ "/Export/loww-xplane-buildings.ac", 48.117921, 16.560051 );

io.include("/fghome/Nasal/common-geo.nas");

# l r u d

var groups = [
    {name:"loww-terminals",
       bb: [16.556519, 16.570669,  48.123211, 48.116424]
    },
    {name: "loww-businesspark",
       bb: [0, 1, 1, 0]
    },
    {name:"loww-hangars", 
       bb: [0, 1, 1, 0]
    },
    {name: "loww-ga", 
       bb: [0, 1, 1, 0]
    },
    {name:"loww-tank",
       bb: [0, 1, 1, 0] 
    },
    {name: "loww-north" ,
        bb: [0, 1, 1, 0],
    },
    {name: "loww-east",
      bb: [0, 1, 1, 0]
    }
];

pathout=getprop("/sim/fg-home") ~ "/Export/";

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
        g["ref"]=geo.Coord.new();
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
        #thispos.dump(); 
            
        foreach(var g; groups) {
             if (geoinside(thispos, g.bb)) {
                print("splitup: add ", mainmodel.obj[i].name );
                
                g.model.addac(mainmodel, i); 
             }    
        }
   }
   
   if (1) {
       
      for (var j=0; j < size(groups); j+=1) {
        
        groups[j].model.save(pathout~groups[j].name~".ac",2);
        
        # outline = "OBJECT_STATIC "~cityfile~" "~ refpoint[j].lon() ~" "~ refpoint[j].lat() ~" "~ refpoint[j].alt() ~" 0.0";
        # add2stg(stg, refpoint[j], outline);
      }
   }
   
#   write all stg files   
#   foreach(var k; keys(stg)) {   
#      var f = io.open(pathout ~ k ~ '.stg','w');
#      io.write(f, stg[k]);
#      io.close(f);
#   }
print("done.");

#   print(total, " objects placed (", total/l*100, "%, in city: ", incity/l*100 ,"%). Too close: ", tooclose, ". unknown: ", unknown );
};
