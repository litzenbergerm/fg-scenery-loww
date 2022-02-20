# this script splits up the whole LOWW (or LOWS or other) ac3d file into building groups for more
# efficient loading. for each group the COG is calculated and a corresponding
# line for the .stg file is generated. An XML for activiting night textures is
# automatically generated together with the .ac file.

# call with this lines from fg nasal console:

#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/object_splitup.nas");
#object_splitup.do( "Aircraft/working/loww_split.nas" );

io.include("/fghome/Nasal/common-geo.nas");

var pathout=getprop("/sim/fg-home") ~ "/Export/";

var animation_preamble = "<animation>\n  <type>material</type>\n";
var animation_post = "  <condition>\n    <greater-than>\n    <property>/sim/time/sun-angle-rad</property>\n" ~
    "    <value>1.57</value>\n    </greater-than>\n  </condition>\n  <emission>\n     <red>1</red><green>1</green><blue>1</blue>\n  </emission>\n" ~
    "</animation>\n";

var makelit = func (fn) {
  return string.replace(fn, ".png", "_LIT.png");
};

var do = func (setfile) { 

    io.include(setfile);
    
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
        g["objlist"]= {};
        g["cog"]= [0,0,0];
        g["n"] = 0;   
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
        
    # loop through all objects and assign to group
    for (var i=0; i < l; i+=1) {
    
        var cog = mainmodel.centroid(-1, i); # in meters
        var bb = mainmodel.bbox(i);
        debug.dump(bb);
        
        #find the cog position of this object in wgs84
        
        var thispos = Dxy2wgs(refpoint, ac2bl(cog) ); # in wgs84
        var thisalt = geo.elevation(thispos.lat(), thispos.lon());
        print("testing... ", mainmodel.obj[i].name );
        thispos.dump(); 
            
        foreach(var g; groups) {
            
            var add_this_obj=0;
            
            if ( contains(g, "obj") ) {
                var obj_in_list = isin( string.replace(mainmodel.obj[i].name,'"','') , g.obj );
                if ( obj_in_list != -1) 
                   add_this_obj=1;
            } else if ( contains(g, "bb") ) {        
                if ( geoinside(thispos, g.bb) ) 
                   add_this_obj=1;
            } else {
                die("splitup: wrong group list format");
            }    
            
            if (add_this_obj) {
                    print("splitup: add ", mainmodel.obj[i].name, " to ", g.name );
                    g.cog = add3d(g.cog, cog); # add to sum COG of group, meters
                    
                    g.model.addac(mainmodel, i);
                    g.objlist[g.n] = { 
                          name: string.replace(mainmodel.obj[i].name, '"', "") , 
                          tex:  string.replace(mainmodel.obj[i].texture , '"', "") ,
                          bb:   bb,
                          pos:  [thispos.lat(), thispos.lon(), thisalt],
                          cog:  cog
                          };     
                    g.n +=1;
            }    
        }
    }
   
    # write all groups' ac model files   
    var f1 = io.open(pathout ~ "splitobjects.stg","w");
   
    # loop through all objects of a group and join
    foreach(var g; groups) {
        n=size(g.model.obj);
        if (n>0) {
            g.cog = [g.cog[0]/n, g.cog[1]/n, g.cog[2]/n];  # ref. point at avg. X-Y-Z cog of group, in meters
            g.refpoint = Dxy2wgs(refpoint, ac2bl(g.cog) ); # cog of group, in wgs84
            
            # check terr. heigth of this group refpoint
            var myalt = geo.elevation(g.refpoint.lat(), g.refpoint.lon());    
            g.refpoint.set_alt(myalt);
            
            #shift all buildings of group by -cog (to cog)
            for(var i=0; i<n; i+=1) {
                g.model.recentercog(i);
                bb = g.model.bbox(i);
                if (ALIGN2GROUND) {
                    
                    # align all objects of group all to same to ground level z=0
                    var shiftz = -bb.min[1];
                    
                } else {
                    
                    # align all objects of group to the terrain ground level
                    var shiftz = -bb.min[1] - (g.refpoint.alt() - g.objlist[i].pos[2]);
                    
                }    
                g.model.transobj( [-g.cog[0], shiftz, -g.cog[2]], i);
            }
            
            if (JOINALL) {
                 #combine all buildings into one model
                 var atlas = g.model.joinall(g.name);
                 g.atlas = atlas;
            }
            
            g.model.save(pathout~g.name~".ac",2);
            
            outline = "OBJECT_STATIC " ~ OBJSUB ~ g.name~".xml "~ fix(g.refpoint.lon(),8) ~" "~ fix(g.refpoint.lat(),8) ~" "~ fix(g.refpoint.alt(),2) ~" 0.0";
            io.write(f1, outline~"\n");
        } else {
            print("splitup: ** Warning ** group has no objects ", g.name);
        }    
            
        
        # add2stg(stg, refpoint[j], outline);
   }
   io.close(f1);
   
   # write all xml files for night textures change
   
   foreach (var g; groups) {   
       
      var f = io.open(pathout ~ g.name ~ ".xml","w");
      io.write(f, '<?xml version="1.0" encoding="UTF-8"?>'); 
      io.write(f, gpltxt);
      io.write(f, "\n<PropertyList>\n\n" ); 
      io.write(f, "<path>"~g.name~".ac</path>\n" ); 
      
      if (JOINALL) {
          
        if (!contains(g, "atlas"))
             die("splitup: group has no texture atlas! ", g.name);
             
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

};
