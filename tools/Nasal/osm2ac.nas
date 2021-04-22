#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/osm2ac.nas");
#osm2ac.do(getprop("/sim/fg-home") ~ "/Export/loww-airport-buildings.csv",48.117921, 16.560051);

io.include("/fghome/Nasal/common-geo.nas");

var issame = func (a,b) {
  return (a.lat()==b.lat() and a.lon()==b.lon());
};

var WKT2coord = func(s, alt = 0) {
  var u = split( '(((', s);
  var v = split( ')))', u[1]);
  
  var out =[];
  foreach (var x; split(",", v[0]) ) {
    var k = split(" ",x);
    # append lat, lon pair
    append(out, geo.Coord.new().set_latlon( k[1], k[0], alt ));
  }
  
  if (size(out)<3)
      die("need 3 points for WKT import");
  
  return out;
};

var createWallsVert = func(n) {
  var out=[];
  for (var i=0; i < n-1; i+=1) {
    append(out, [i, i+1, i+n+1, i+n]);
  }
  append(out, [n-1, 0, n, 2*n-1]);
  return out; 
};

var createRoofVert = func(n) {
    var out=[];
    for (var i=0; i<n; i+=1) {
         append(out, i+n); 
    }
    return out;  
};

var edgeorient = func(x, v) {
  #note: in ac3d +y points EAST, +x points SOUTH!  
  dx = v[x[1]][0] - v[x[0]][0];
  dy = v[x[1]][2] - v[x[0]][2];
  return fix360( math.atan2(dy,-dx)*R2D );
};    

# main

var SINK = 2.0;
var HEIGHT = 10.0;
var LEVEL = 4.0;

var do = func (conf, reflat, reflon) { 
    #io.include( conf );
    
    var refpoint = geo.Coord.new().set_latlon( reflat, reflon );
    refpoint.set_alt( geo.elevation( reflat, reflon ) );

    
    #load cvs coloumns
    var cc = getcsv(conf);
    var ccID = getidx(cc[0], "id");
    var ccWKT = getidx(cc[0], "WKT");
    var ccLEV = getidx(cc[0], "building_l");
    var ccHEI = getidx(cc[0], "building_h");
    var ccMINH = getidx(cc[0], "min_h");
    var ccBUI = getidx(cc[0], "building");
    var ccRoofShape = getidx(cc[0], "roof_shape");
    var ccRoofOri = getidx(cc[0], "roof_orien");
    var ccRoofH = getidx(cc[0], "roof_heigh");
    
    # new ac3d obj
    var city = libac3d.Ac3d.new();
    var L = 0;
    var h = 0.0;
    
    # add building objs
    
    for (var i=1; i < size(cc); i=i+1) {
      city.addobj( "building."~ (cc[i][ccID] == 1 ? i : cc[i][ccID]) );
      
      var x = WKT2coord(cc[i][ccWKT]);
      
      # no closed polygons
      if (issame(x[0],x[-1]))
        x = x[0:-2];

      var h = geo.elevation( x[0].lat(), x[0].lon()); 
      
      # for all bottom vertices      
      foreach (var p; x) {
         #check alt for this building
         if (cc[i][ccMINH] != "")
            p.set_alt(h+cc[i][ccMINH] );
         else    
            p.set_alt(h-SINK);
         
         var d = Dwgs2xy(refpoint, p);
         city.addvert( libac3d.bl2ac(d) ); # y is z in blender,z is -y in blender
      }

      if (cc[i][ccHEI] != "") 
         h = h + cc[i][ccHEI];
      elsif (cc[i][ccLEV] != "")
         h = h + cc[i][ccLEV]*LEVEL;
      else
         h = h + HEIGHT;
      
      #for all roof vertices      
      foreach (var p; x) {
         #set height for this building
         p.set_alt(h);         
         var d = Dwgs2xy(refpoint, p);
         city.addvert( libac3d.bl2ac(d) );
      }
      
      #make all surfaces of the building object
      var walls = createWallsVert(size(x));
      foreach(var w; walls) {
         city.addsurf(libac3d.flip(w));
      }

      #buildings parts get no roof!
      if (cc[i][ccBUI] != "part") {
        #if quad and has gabled roof
        if (size(x)==4 and cc[i][ccRoofShape]=="gabled" and cc[i][ccRoofOri]!="") {
            var ro = cc[i][ccRoofOri];
            var rh = (cc[i][ccRoofH] == "") ? 2 : cc[i][ccRoofH];
            
            #test 2 edge orientations of building footprint and add the 2 new roof verts
            var rooftest=0;
            foreach(var roe; [[4,5], [5,6]]) {
                var eo=edgeorient(roe, city.vert());
                #get the mid-points
                var mid1 = city.centroid([roe[0], roe[1]]);
                var mid2 = city.centroid([roe[0]+2, (roe[1]+2)>7 ? 4 : roe[1]+2]);
               
               if ((ro=="N" or ro=="S") and ((eo>45 and eo<135) or (eo>225 and eo<315))) {
                    #add roofheight                   
                    city.addvert(mid1[0],mid1[1]+rh,mid1[2]);
                    city.addvert(mid2[0],mid2[1]+rh,mid2[2]);
                    rooftest=(roe[0]==4) ? 1 : 2; 
               }
               
               if ((ro=="W" or ro=="E") and ((eo>135 and eo<225) or (eo>315 or eo<45))) {
                    #add roofheight
                    city.addvert(mid1[0],mid1[1]+rh,mid1[2]);
                    city.addvert(mid2[0],mid2[1]+rh,mid2[2]);
                    rooftest=(roe[0]==4) ? 1 : 2; 
               }
               
            }
            
            if (rooftest==0)
                die("osm2ac: failed to find gabled roof edges");

            if (rooftest==1) {
                city.addsurf(libac3d.flip([4,8,9,7]));
                city.addsurf(libac3d.flip([8,5,6,9]));
                city.addsurf(libac3d.flip([4,5,8]));
                city.addsurf(libac3d.flip([6,7,9]));
            } else {
                #add gable and roof surfs
                city.addsurf(libac3d.flip([4,5,8,9]));
                city.addsurf(libac3d.flip([9,8,6,7]));
                city.addsurf(libac3d.flip([7,4,9]));
                city.addsurf(libac3d.flip([5,6,8]));
            }
       
        } else {
            var roof = createRoofVert( size(x) );
            city.fill(libac3d.flip(roof));
        }
      }
      
      # correct for local center of the building bc:
      var bc = city.centroid();
      #debug.dump(bc);
      city.obj[-1].loc = bc;     
      for (var j=0; j < size(city.obj[-1].vert); j=j+1) {
             city.obj[-1].vert[j] = libac3d.sub3d( city.obj[-1].vert[j], bc );
      }
      
    }
   
   city.save(getprop("/sim/fg-home") ~ "/Export/loww-airport-buildings.ac",2);
   
   var outline = "OBJECT_STATIC loww-airport-buildings.ac "~ refpoint.lon() ~" "~ refpoint.lat() ~" "~ refpoint.alt() ~" 0.0";
   
   var tilex = tileIndex(refpoint.lat(), refpoint.lon());
   var f = io.open(getprop("/sim/fg-home") ~ "/Export/" ~ tilex ~ '.stg','w');
   io.write(f, outline);
   io.close(f);
   
   
   #print(total, " objects placed (", total/l*100, "%, in city: ", incity/l*100 ,"%). Too close: ", tooclose, ". unknown: ", unknown );
};
