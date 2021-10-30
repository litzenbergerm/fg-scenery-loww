#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/object_placement.nas");
#object_placement.do( "/Aircraft/working/loww_scenery_conf.nas" );

io.include("/fghome/Nasal/common-geo.nas");
      
var do = func (conf) { 
   io.include( conf );
   
   if (USE_3DCITY) {
    #check for all models and pre-load models
    foreach (var x; keys(obj)) {
      foreach (var m; obj[x]) {
        if (find(m, cityobj) != -1 and !contains(citymodels, m) ) {
            #chache the 3d building model
            citymodels[m] = libac3d.Ac3d.new(modelpath~m);
            print("loading object model:", m);
        }
      }
    }  
   
    #load the city centers
    var cc = getcsv(citycenters);
    var ccLAT = getidx(cc[0], LAT);
    var ccLON = getidx(cc[0], LON);
    var ccID = getidx(cc[0], "ID");
    
    # add empty city objects
    var city = {};
    var refpoint = [nil, ];
    for (var i=1; i < size(cc); i=i+1) {
       city[cc[i][ccID]] = libac3d.Ac3d.new();
       append(refpoint, geo.Coord.new().set_latlon( cc[i][ccLAT], cc[i][ccLON] ) );
       refpoint[-1].set_alt( geo.elevation( cc[i][ccLAT], cc[i][ccLON] ) );
    }
   }
   
   var cycl={};
   foreach (var o; keys(obj))
       cycl[o]=0;
   
   var a = getcsv(filein);
   var stg = { };
   var params = { };
   
   # search headers for codes   
   var iLAT = getidx(a[0], LAT);
   var iLON = getidx(a[0], LON);
   var iTYP = getidx(a[0], TYP);
   var iORI = getidx(a[0], ORI);
   
   debug.dump(a[0]);
   
   if (iLAT==nil or iLON==nil or iTYP==nil or iORI==nil)
      die("cvs field codes not found in header! ");
   
   var out = [a[0]]; 
                     
   var l = size(a);
   print(l-1, " objects in file.");
   
   var lastpos = geo.Coord.new();
   var thispos = geo.Coord.new();
   
   var lat = a[1][iLAT];
   var lon = a[1][iLON];
   lastpos.set_latlon(lat, lon);
   
   var thisori = int( rand()*360);
   var lastori = int( rand()*360);
   var modelori = 0;
   
   var thisobj = nil;
   var lastobj = nil;
   var outline = "";
   var total = 0;
   var tooclose = 0;
   var unknown = 0;
   var incity = 0;
   var objsel = 0;
   var param = "";
     
   for (var i=1; i < l; i=i+1) {
   
      # loop through all buildings
      var thist = string.uc( a[i][iTYP] );
      
      # check if this typ is a parameter object
      # separate parameter from object type
      
      if (find("@", thist ) > -1) {
            var temp = split("@", thist);
            thist = temp[0];
            param = temp[1];
       } else {
            param = "";
       }      
      
      if (!contains(obj, thist)) {
        print("# ***** ERROR ***** object code unknown: ",thist);
        unknown += 1;
      } else {
      
        # check if this typ is a parameter object
        # save parameter to list
        
        if (param != "") {
           if (contains(params, thist)) 
              append( params[thist], param );
           else
              params[thist] = [param,];
        }
     
        # get point get_elevation
        lat = a[i][iLAT];
        lon = a[i][iLON];
        
        var e = geo.elevation(lat ,lon);
        if (e == nil) {
          print('warning no elevation for ', thist, " at ",lat," ",lon );
          e=0;
        }
        
        append(out, [lat, lon, e, thist]);
        
        if (PLACEMENT=="rand") {
            objsel = int( rand() * size(obj[thist]) );
        } else {
            cycl[thist] = (cycl[thist]==size(obj[thist])-1 ? 0 : cycl[thist]+1);
            objsel = cycl[thist];
        }    
        
        
        thispos.set_latlon(lat, lon, e);        
        var tolast = thispos.direct_distance_to(lastpos);
        
        if (tolast < MINDIST) {
          print("# ***** WARN ***** too close omitting");
          tooclose += 1;
          
        } else {
            if (typeof( obj[thist][objsel] ) == "scalar") {
                thisobj = obj[thist][objsel];
                modelori = 0;
                modeloffs = 0;
                
            } else {
                # correct for model internal orientation and z-pos
                thisobj = obj[thist][objsel].model;
                modelori = obj[thist][objsel].model_ori;
                modeloffs = obj[thist][objsel].zoffset;
            }
            
            # if objects are really close together make same orientation and name if same type
            # for unknown reason orientations must be in negative values
            
            if (tolast < 45 and lastobj != nil and lastt == thist) { 
              thisori = (iORI==nil) ? lastori : -a[i][iORI];
            } else { 
              thisori = (iORI==nil) ? int( rand()*360 ) : -a[i][iORI];
            }
            
            if (find("Scenery/", thisobj ) > -1) {
              var objtype = "OBJECT_SHARED ";
            } else {
              var objtype = "OBJECT_STATIC ";
            }  
            
            if (param != "") {
                thisobj = split(".", thisobj)[0] ~ param ~ "." ~ split(".", thisobj)[1]; 
            }
            
            outline = objtype ~ thisobj ~" "~ lon ~" "~ lat ~" "~ (int(e*100.0)/100.0 - modeloffs) ~" "~ fix360(thisori+modelori) ~".0 0.0 0.0";
                
            #add to main 3d model of city if possible
            if (objtype == "OBJECT_STATIC " and contains(citymodels, thisobj) and USE_3DCITY) {
                
                  #find a city centre where this building fits to
                  for (var j=1; j < size(cc); j=j+1) {
                    
                    #reference point for this city
                    if ( thispos.direct_distance_to(refpoint[j]) < CITY_RADIUS ) { 
                        var t = Dwgs2xy(refpoint[j], thispos);
                        city[ cc[j][ccID] ].addac( citymodels[thisobj] );
                        city[ cc[j][ccID] ].rotobjY(thisori);
                        city[ cc[j][ccID] ].transobj(t);
                        # use one building only once
                        total += 1;
                        incity += 1;
                    
                        break;
                    }
                  }
                  # model in 3dcity model?
                  if (j==size(cc)) {
                    total += 1;
                    add2stg(stg, thispos, outline);
                  }
            } else { 
                    
                  # add to STG file   
                  if (ERRS) 
                    print(outline);
                    
                  add2stg(stg, thispos, outline);
                  total += 1;
            }  
            lastori = thisori; # orientation
            lastobj = thisobj; # object name
            var lastt = thist; # object type
            lastpos.set_latlon(lat, lon);
        }
     }
   }
   
   if (USE_3DCITY) {
      #generate the city models
      for (var j=1; j < size(cc); j=j+1) {
        # compose the ac filename from obejctname and tileindex
        var cityfile = tileIndex(refpoint[j].lat(), refpoint[j].lon() ) ~ cc[j][ccID] ~".ac";
        
        city[ cc[j][ccID] ].joinall();
        city[ cc[j][ccID] ].save(pathout~cityfile,2);
        
        outline = "OBJECT_STATIC "~cityfile~" "~ refpoint[j].lon() ~" "~ refpoint[j].lat() ~" "~ refpoint[j].alt() ~" 0.0";
        #outline = "OBJECT_STATIC "~cityfile~" "~ refpoint.lon() ~" "~ refpoint.lat() ~" "~ refpoint.alt() ~" 0.0";
        add2stg(stg, refpoint[j], outline);
      }
   }
   
   #write all stg files   
   foreach(var k; keys(stg)) {   
      var f = io.open(pathout ~ k ~ '.stg','w');
      io.write(f, stg[k]);
      io.close(f);
   }
   
   #write all parameterized model XML files
      
   #debug.dump(params);
   foreach(var k; keys(params)) {   
      # read the template object xml. in this, parameter must be marked as '@'
      var filexml = obj[k][0];
      var modelxml = io.readfile(pathout ~ filexml );
      
      foreach(var p; params[k]) {
         var f= io.open(pathout ~ split(".", filexml)[0] ~ p ~ "." ~ split(".", filexml)[1] ,'w');
         io.write(f, string.replace(modelxml, "@", p));
         io.close(f);
      }
   }
   
   
   print(total, " objects placed (", total/l*100, "%, in city: ", incity/l*100 ,"%). Too close: ", tooclose, ". unknown: ", unknown );
};
