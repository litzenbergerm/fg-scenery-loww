# common functions for geo

var ECIRC=geo.ERAD*2.0*math.pi/360.0;

# convert from ac to blender axes:
# y is z in blender 
# z is -y in blender

var bl2ac = func(t) { return [t[0], t[2], -t[1]] }; 
var ac2bl = func(v) { return [v[0], -v[2], v[1]] };
var add3d = func(a,b) { return [a[0]+b[0], a[1]+b[1], a[2]+b[2]] };
var sub3d = func(a,b) { return [a[0]-b[0], a[1]-b[1], a[2]-b[2]] };
var equal3d = func(a,b) { return (a[0]==b[0] and a[1]==b[1] and a[2]==b[2]) };

var dsquare = func(a,b) { 
   var d=sub3d(a,b);
   return ( d[0]*d[0] + d[1]*d[1] + d[2]*d[2]);
}   

var fix = func(x, p=3) {
 var k = find(".",""~x);
 
 if (k==-1) 
    return ""~x;
 else
    return substr(""~x, 0, k+p+1);
 
};

var fix360 = func (x) {
    var u = math.fmod(x*1.0, 360.0); 
    if (u<0) return 360+u;
    return u; 
};
    
var get_elevation = func (lat, lon) {
        var info = geodinfo(lat, lon);
        if (info != nil) {          
          return [ info[0], (info[1] == nil) ? 1 : info[1].solid ];
        } else { 
          return nil; 
        }
};

var getcsv = func (path, delimeter=",") {
  
  var file = io.open(path);
  var out = [];
  var line = io.readln(file);
  
  while (line != nil) {
    var r = [];
    var tmp = split('"',line);
    
    # handle quoted field
    if (size(tmp)==3) {
      tmp[1] = string.replace(tmp[1], delimeter , ";/" );
      line = tmp[0]~tmp[1]~tmp[2];
    }
    
    foreach (var x; split(delimeter ,line) ) {
      append(r,string.replace(x, ";/" , delimeter ) );
    }      
    append(out, r);       
    var line = io.readln(file);
  }
  return out;
};

var getidx = func (h, code) {
  var idx = nil;
  
  for (var i=0; i < size(h); i=i+1)
    if (h[i] == code) idx = i;
  
  return idx;
}

var Dwgs2xy = func(from, to) {
  # in fg scenery :
  # blender +y is east
  # blender +x is south
  # blender +z is up
  
  var lat1 = from.lat();
  var lon1 = from.lon();
  var lat2 = to.lat();
  var lon2 = to.lon();
  
  var x = -ECIRC*(lat2-lat1);
  var y = math.cos((lat1+lat2)*0.5*D2R)*ECIRC*(lon2-lon1);
  var z = to.alt() - from.alt();
  
  return [x,y,z];
};

var add2stg = func(stg, pos, line) {
  #var tilex = geo.tile_path(pos.lat(), pos.lon());
  var tilex = tileIndex(pos.lat(), pos.lon());
  
  if (!contains(stg, tilex)) {
    stg[tilex] = "";
  }
  
  stg[tilex] ~= line ~ "\n";
}
