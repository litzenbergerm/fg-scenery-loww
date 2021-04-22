#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/object_collect.nas");
#object_collect.do( "/fghome/xplane/loww_xplane_conf.nas", 48.117921, 16.560051 );

io.include("/fghome/Nasal/common-geo.nas");
      
var do = func (conf, reflat=nil, reflon=nil) { 
    io.include( conf );
   
    #load the models positions
    var a = getcsv(filein, delimeter=" ");
    var stg = { };
   
    # search headers for codes   
    var iLAT = getidx(a[0], LAT);
    var iLON = getidx(a[0], LON);
    var iTYP = getidx(a[0], TYP);
    var iORI = getidx(a[0], ORI);
    
    debug.dump([iLAT, iLON, iTYP, iORI]);
    var out = [a[0]]; 
                        
    var l = size(a);
    print("collect: ", l-1, " objects in file.");
    
    var refpoint=[];
    append(refpoint, geo.Coord.new());
    var thispos = geo.Coord.new();
    
    if (reflat==nil or reflon==nil) {
        #set reference point to first building location TODO check later if that is good
        var e = geo.elevation(a[1][iLAT], a[1][iLON]);    
        refpoint[0].set_latlon(a[1][iLAT], a[1][iLON], e);
    } else {
        var e = geo.elevation(reflat, reflon);    
        refpoint[0].set_latlon(reflat, reflon, e);
    }    
        
    var city = libac3d.Ac3d.new();
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
    for (var i=1; i < l; i+=1) {
        
        lat     = a[i][iLAT];
        lon     = a[i][iLON];
        thist   = a[i][iTYP];
        modelori = fix360(a[i][iORI]);
        
        print("collect: ", thist);
        
        # get current point elevation
        e = geo.elevation(lat ,lon);
        thispos.set_latlon(lat, lon, e);
        
        append(out, [lat, lon, e, thist]);
        t = Dwgs2xy(refpoint[0], thispos);
            
#        if (find("/", thisobj ) > -1) {
#            var objtype = "OBJECT_SHARED";
#        } else {
#            var objtype = "OBJECT_STATIC";
#        }  
                
        #add to main 3d model of city 
        if (objtype == "OBJECT_STATIC") {
            #load the object 3d file
            var model = libac3d.Ac3d.new(modelpath~thist);
            print("----------------------------");
            model.joinall();
            model.remdup(0.1); # remove duplicate verts with less than 10 cm distance
            model.dump();
            model.objname( string.replace( string.replace(thist, "MyObjects\\Buildings\\", ""), ".ac", "" ));
            
            city.addac( model );
            city.rotobjY( modelori );
            # convert to FG coordinate system an translate
            city.transobj( bl2ac(t) );
            total += 1;
        }
   }
   
   if (USE_3DCITY) {
      # generate the city model(s)
      # make the city clusters later
       
      for (var j=0; j < 1; j+=1) {
        
        #cannot use joinall because the model have different texture files
        #city[ cc[j][ccID] ].joinall();
        
        city.save(pathout~cityfile,2);
        
        outline = "OBJECT_STATIC "~cityfile~" "~ refpoint[j].lon() ~" "~ refpoint[j].lat() ~" "~ refpoint[j].alt() ~" 0.0";
        add2stg(stg, refpoint[j], outline);
      }
   }
   
   #write all stg files   
   foreach(var k; keys(stg)) {   
      var f = io.open(pathout ~ k ~ '.stg','w');
      io.write(f, stg[k]);
      io.close(f);
   }
   
   #print(total, " objects placed (", total/l*100, "%, in city: ", incity/l*100 ,"%). Too close: ", tooclose, ". unknown: ", unknown );
};
