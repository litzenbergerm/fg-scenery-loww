# a class and helper functions for loading and manipulating 3D-models in AC3D files

io.include("fghome/Nasal/common-geo.nas");

var NL = utf8.chstr(10);
var ACSECRET = "AC3Db";

var parsefromto = func(s, f, t=",") {
  var a=find(f,s);
  var b=find(t, substr(s,a+size(f)));
  
  if (a==-1 or b==-1)
     return nil;
     
  return substr(s,a+size(f),b);
};

var otherdims = func(dim) {
  if (dim==0) return {a:1, b:2};
  if (dim==1) return {a:0, b:2};
  if (dim==2) return {a:0, b:1};
};

var deepcopy = func(x) {
   var a=x[0:-1];
   return a;
};

# remove an element from a vector
var remove = func(x, v) {
   var a=[];
   foreach(var i; v)
       if (i != x) append(a, i);
       
   return a;
};

# flip a vector
var flip = func(x) {
   var a=[];
   var n=size(x);
   for(var i=n-1; i>=0; i-=1)
       append(a, x[i]);       
   return a;
};
   
var getclosed3 = func(p, idx) {
    # for closed polygon indices idx 
    
    for(var i=0; i<size(idx); i=i+1) {
        if (idx[i]==p) break;
    }
    
    if (i==0)
        return [idx[-1], idx[0], idx[1]]; 
    
    if (i==size(idx)-1)
        return [idx[-2], idx[-1], idx[0]];
    
    return [idx[i-1], idx[i], idx[i+1]];
    
};

var equalvert = func(a,b) { 
    if (size(a) != size(b)) 
        return 0;
    
    var n = size(a);
    var e = 1;
    for(var i=0; i<n; i+=1) {
        if (!equal3d(a[i],b[i])) 
            return 0;
    }
    return 1;
};    

# =================================================================
# class for loading and manipulating models in AC3D files
# =================================================================

var Ac3d = {
    new: func(f=nil) {
        var m = { parents: [Ac3d] };
        
        m.header = 'OBJECT world' ~ NL ~ 'name "none"';
        m.obj = [];
        m.mat = ['MATERIAL "Default" rgb 1.0 1.0 1.0  amb 0.2 0.2 0.2  emis 0.0 0.0 0.0  spec 0.5 0.5 0.5  shi 0 trans 0.0', ];
        if (f != nil) 
            m.load(f);
        
        return m;
    },
    
    newobj: func() {
            var o = {
              name: '""',
              data: '',
              texture: '',
              rot: nil,
              loc: [0,0,0],
              texrep: [1, 1],
              vert: [],
              surf: [],
             };
            
             return o;
    },
    
    objname: func(name="", objidx=-1) {
       if (name == "")
           me.obj[objidx].name = '"object.'~size(objidx)~'"';
       else
           me.obj[objidx].name= '"' ~ name ~ '"';
    },
    
    addobj: func(name="") {
       append(me.obj, me.newobj());
       if (name == "")
           me.obj[-1].name = '"object.'~size(me.obj)~'"';
       else
           me.obj[-1].name = '"'~name~'"';
       
       return size(me.obj)-1;
    },
    
    addvert: func() {
        # can be either called as (vector3, objectindex) or
        # as (x,y,z, objectindex)
        
        
        if (size(arg)==1 and typeof(arg[0])=="vector") {
            append( me.obj[-1].vert, arg[0]);
            return (size(me.obj[-1].vert)-1);
        }
        
        if (size(arg)==2 and typeof(arg[0])=="vector") {
            append( me.obj[arg[1]].vert, arg[0]);
            return (size(me.obj[arg[1]].vert)-1);
        }
        
        if (size(arg)==3 and typeof(arg[0])=="scalar") {
            append( me.obj[-1].vert, [arg[0], arg[1], arg[2]]);
            return (size(me.obj[-1].vert)-1);
        }
        
        if (size(arg)==4 and typeof(arg[0])=="scalar") {
            append( me.obj[arg[3]].vert, [arg[0], arg[1], arg[2]]);
            return (size(me.obj[arg[3]].vert)-1);
        }
        
        die("addvert: arguments error");
        
    },
    
    addsurf: func(idx, objidx=-1) {
        var l = size(me.obj[objidx].vert);
        var n = size(idx);
        
        #add empty surface        
        append(me.obj[objidx].surf, {refs:[], mat:0, flag:"20"});
        
        foreach(var k; idx) {
            if (k>l-1)
                die("libac3d.addsurf:vertex index is out of bounds");
            append( me.obj[objidx].surf[-1].refs, [k,0,0] );
        }           
    },
    
    remdup: func(d=0.01, objidx=-1) {
        # remove duplicate verts of object
        # if distance smaller then d, default 1cm
        
        var idx=[];
        var xch=[];
        var v = me.obj[objidx].vert; # reference!
        var l = size(v);
        
        # prepare index lists
        for (var i=0; i<l; i+=1) { 
            append(idx,i);
            append(xch,i);
        }
        
        # loop through all vertices combinations and test (squared) distance:
        var dd = d*d;
        for (var i=0; i<l; i+=1) {
           idx_1 = idx[i];
           if (idx_1 != nil) {
                for (var i2=i+1; i2<l; i2+=1) {
                    idx_2 = idx[i2];
                    if (idx_2 != nil) {
                    
                       # check distance 1-to-2
                       if (dsquare(v[idx_1],v[idx_2])<dd) {
                          #mark this vertex for removal!
                          idx[idx_2] = nil;
                          xch[idx_2] = idx_1;
                       }
                       
                    }
                }
           }    
        }       
        
        # new vertices list
        # where idx==nil vertices will be removed:
        
        var vout=[];
        for (var i=0; i<l; i+=1) {
            if (idx[i] != nil) {
                append(vout, v[i][0:2]);
            }    
        }
        
        me.obj[objidx].vert=vout;
        
        # re-align indices to account for delected vertices:
        var shft = 0;
        for (var i=0; i<l; i+=1) { 
            if (idx[i]==nil)
                shft+=1
            else
                idx[i]-=shft
        }       
        
        #re-index all surfaces        
        var ls = size(me.obj[objidx].surf);
        
        for(var j=0; j<ls; j+=1) {
            n=size(me.obj[objidx].surf[j].refs);
            for(var k=0; k<n; k+=1) {
                # exchange vertex index in all surfaces
                var x = me.obj[objidx].surf[j].refs[k][0];
                me.obj[objidx].surf[j].refs[k][0] = idx[ xch[x] ];
            }
        }
    },
    
    fill: func(idx, tria=0, objidx=-1) {
        # fill vertices idx with a surface
        # if more than 4 verts use earclipping for 
        # triangulation of the surface
        # default object to use is the last obj
        
        var n=size(idx);
        # if surface has 3 verts or triangulation is not required
        if (n==3 or !tria) {
            me.addsurf(idx, objidx);
            return;
        }
        
        # check if all vertices are in a x,y,z - plane
        if (me.inplane(idx, objidx)==-1) 
            die("libac3d.fill: needs vertices in x,y or z-plane");
        
        # fill a polygon        
        var poly = deepcopy(idx);
        var i = 0;
        var lastear = -1;
        
        # cycle through all vertices
        while(size(poly)>3 and lastear<n*2) {
            lastear += 1;
            
            # try to clip the ear at i-th vertex 
            var clip = me.clip(poly[i], poly, objidx);
            var ear  = clip[0];

            if (ear != nil)
              poly = clip[1];

            if (ear==nil) {
                i+=1;
            } else {
                #create a surface from this ear, vert index i stays fixed
                me.addsurf(ear, objidx);
                lastear = 0;
            }
            
            if (i>size(poly)-1) 
              i=0;
        }
        
        #add the final ear
        if (size(poly)==3)
            me.addsurf(poly, objidx);
    },

    clip: func(p, idx, objidx) {

        var ear = getclosed3(p, idx);
        var vert = me.obj[objidx].vert;

        if (!me.isconvex3(ear, objidx)) {
            return [nil, nil];
        } else {
            # test if no other vertex inside ear
            var pinside = 0;
            
            foreach(var i; idx) {
                if (me.inside3(ear,vert[i])) {
                    pinside=1;
                    break;
                }
            }
            if (pinside)
                return [nil, nil];
                
            # remove the ear from the poly 
            var newidx = remove(p, idx);
            return [ear, newidx];
        }
    },    
    
    inplane: func(idx, objidx=-1) {    
        # check for in plane axis
        var objv=me.obj[objidx].vert;
        var l=size(idx);

        var first=objv[idx[0]];
        var equal=[1, 1, 1];

        foreach(var v; idx) { 
            foreach (var dim;[0,1,2]) 
               equal[dim] = (equal[dim] and (first[dim] == objv[v][dim]));
        }
        
        foreach (var dim;[0,1,2]) 
           if (equal[dim]==1) return dim;
        return -1;
    },    
        
    parseobj: func(h, v, s) {
        var name= parsefromto(h,"name ");
        var text= parsefromto(h,",texture ");
        var loc = parsefromto(h,",loc ");
        var dat = parsefromto(h, ",data ");
        var rot = parsefromto(h, ",rot ");
        var rep = parsefromto(h, ",texrep ");
        var vert= v;
        var surf= s;
    
        var oo = me.newobj();
        if (name != nil) 
            oo.name = name;
        if (text != nil) 
            oo.texture = text;
        if (loc != nil) 
            oo.loc = split(" ",loc);
        if (dat != nil)
            oo.data = substr(h, find("data "~dat, h), dat);
        if (rep != nil)
            oo.texrep = split(" ", rep);

        if (rot != nil) {
          # 3 x 3 rotation matrix as a 9 element vector
          oo.rot = split(" ", rot);
        }
        
        #parse vertices
        var y=[];
        if (vert != nil) {
            foreach (var x; split(",",vert)[1:-2] ) {
                append(y, split(" ", x) );
            }
            oo.vert = y;
        }
            
        #parse surfaces 
        var y = {refs:[], mat:0, flag:""};
        if (surf != nil) {
            #all after 'SURF ' is a surface
            # SURF 0x..
            # mat ..
            # refs ..
            # num0 tex_x tex_y
            
            # what is used in this file 0x or 0X?
            var ss = (find("SURF 0x", surf)==-1) ? "SURF 0X" : "SURF 0x";
                
            surf = surf ~ ss;
            
            foreach (var x; split(ss, surf)[1:-2] ) {
                y=[];               
                #all after 'refs ' are surface edges
                var z = split(",refs ", x);
                #all surface edge verts lines 'num tex_x tex_y'
                foreach(var ss;  split(",", z[1])[1:-2] ) {
                    append(y, split(" ", ss ));
                }
                append(oo.surf, { refs:y, mat:split(",mat ", z[0])[1], flag:split(",mat ", z[0])[0]});
            }
        }
        return oo;
    },
    
    parsemat: func(s) {
        var out = [];
        var x = split(",", s);
        foreach (var m; x[1:-1]) {
            if (substr(m,0,6)=="OBJECT") 
                break;
            append(out,m);
        }
        return out;        
    },
    
    load: func(fn) {
        var file = io.open(fn);
        var line = io.readln(file);
        var h = ""; #header
        var v = ""; #vertices
        var s = ""; #surfaces
        var l = 0;
        
        var q = [];
        
        if (line != ACSECRET)
            die("libac3d.load: Error - not an AC3D file!");
        
        # read line by line from OBJECT to OBJECT and separate by ,
        while (line != nil) {
          
          if (substr(line, 0, 4) == "kids") {
             #print("surfs->",size(q));
             s = string.join(",", q)~",";  
             q = [];          
          }
              
          if (substr(line, 0, 7) == "numvert") {
             #print("header->",size(q));
             h = string.join(",", q)~",";  
             q = [];          
          }
          
          if (substr(line, 0, 7) == "numsurf") {
             #print("verts->",size(q));
             v = string.join(",", q)~",";  
             q = [];          
          }
          
          # end of an object or world          
          if (substr(line, 0, 4) == "kids") {

               if (substr(s, 0, 5) == ACSECRET) {
                 # this is the header of the ac file  
                 me.header = substr(s, find("OBJECT ", s) );
                 me.mat = me.parsemat(s);
               } else {
                 #print(h,"***",v,"***",s);  
                 append(me.obj, me.parseobj(h, v, s));
               }
          }
          
          l += size(line);
          
          if (l < 500000) { 
            # append lines to buffer q
            append(q, line);
          } else {
            die("libac3d.load : Error - buffer > 500kb, cannot load this ac file.");
          }
          
          #new object start
          if (line == "OBJECT poly") {
             h = "";
             v = "";
             s = "";
             q = [];
             l = 0;
          }
          
          var line = io.readln(file);
        } 
    },
          
    save: func(fn, pr=3) {
       
       var f = io.open(fn,'w');
       io.write(f, ACSECRET ~ NL);
       
       foreach (var m; me.mat) 
           io.write(f, m ~ NL);
       
       foreach (var x; split(",", me.header)) 
           io.write(f, x ~ NL);
           
       io.write(f, "kids " ~ size(me.obj) ~ NL);
       
       foreach (var x; me.obj)  {
          io.write(f, "OBJECT poly" ~ NL ~ "name " ~ x.name ~ NL);
          
          if (x.texture!=nil and x.texture!="") {
             io.write(f, "texture "~x.texture~NL);
             io.write(f, "texrep "~x.texrep[0]~" "~x.texrep[1] ~ NL);
          }
          
          if (x.loc!=nil and x.loc!=[0,0,0])
             io.write(f, "loc "~fix(x.loc[0],pr)~" "~fix(x.loc[1],pr)~" "~fix(x.loc[2],pr)~NL);
          io.write(f, "numvert "~size(x.vert)~NL);
          
          # 3 x 3 rotation matrix as a 9 element vector
          if ( contains(x, "rot") ) 
            if (x.rot!=nil) {
                io.write(f, "rot");
                foreach (var r; x.rot) 
                    io.write(f, " "~fix(r, 6));
                io.write(f, NL);
             }

          #write object vertices
          foreach (var v; x.vert) 
            io.write(f, fix(v[0],pr)~" "~fix(v[1],pr)~" "~fix(v[2],pr)~NL);
            
          #write object surfaces
          io.write(f, "numsurf "~size(x.surf)~NL);
          
          foreach (var s; x.surf) {
             io.write(f, "SURF 0x"~s.flag~"\nmat "~s.mat~"\nrefs "~size(s.refs)~NL);
             foreach (var v; s.refs) 
                io.write(f, v[0] ~ " " ~ v[1] ~ " " ~ v[2] ~ NL);
          }
          io.write(f, "kids 0" ~ NL);
       } 
       io.close(f);
    },
    
    dump: func() {
        print("Objects: ", size(me.obj)); 
        foreach (var x; me.obj) {
            print(x.name, ": ", size(x.vert),"/", size(x.surf), " vert/surf, Texture: ", x.texture );
        }
    },
    
    numobj: func() {
        #return the number of objects in the ac3d
        return size(me.obj);
    },
    
    vert: func(objidx=-1) {
        #return a copy of the vertices of an object in the ac3d,
        #default is the last object        
        return deepcopy( me.obj[objidx].vert );
    },
    
    find: func(name) {
        #return the index of an object by its name,
        #return nil if not found
        
        name = '"'~ name ~ '"';
        
        for (var i=0; i<size(me.obj); i+=1) 
            if (name == me.obj[i].name) break;
        
        if (i==size(me.obj)) 
            return nil;
        
        return i;
    },    
    
    joinall: func(newname="object.000") {
        if (size(me.obj)==0) 
           return [];
         
        var oo = me.newobj();
        # joined objects must share the same texture file!
        # we assume that the texture atlas has the same name as the object
        
        # therefore build a texture 'atlas' before joining objects
        
        var atlas = [];
        foreach (var x; me.obj) {
           if (x.texture==nil or x.texture=="" or x.texture=='""') {
              print("warning: libac3d.joinall, no texture for object "~x.name);
           } else {
            if (isin(x.texture, atlas) == -1)
                append(atlas, x.texture);
           }
        }        
        var atlasn = size(atlas);
        
        oo.texture = '"' ~ newname ~ '.png"'; 
        oo.texrep = me.obj[0].texrep;
        oo.name = '"'~newname~'"';
        
        var offset = 0;
        foreach (var x; me.obj) {
           # add only textured objects! 
           if (x.texture!=nil and x.texture!="" and x.texture!='""') {
           
                foreach (var v; x.vert) {
                    append(oo.vert, add3d(v, x.loc));
                }
                
                # which texture index to use?
                var atlasidx = isin(x.texture, atlas);          
                
                if (atlasidx==-1)
                    die("error: libac3d.joinall, no atlas position for object "~x.name);
                    
                foreach (var s; x.surf) {
                    var ss={refs:[], mat:s.mat, flag:s.flag};
                    foreach (var v; s.refs) 
                    append(ss.refs, [v[0]+offset, 
                                        v[1], 
                                        ((v[2] + atlasidx) / atlasn) ] );
                    append(oo.surf, ss);             
                }
                offset += size(x.vert);
            }    
        }
        me.obj=[oo,];
        
        return atlas;
    },
    
    addac: func(ac, objidx=-1) {
        
        # objidx=-1 means all objects of ac
        
        var matoffset=size(me.mat);
        var newmats = [];
        
        if(me.header == "") 
           me.header = ac.header;
        
        var j=0;
        
        foreach (var x; ac.obj) {
            
            # add this object? -1 means all!
            
            if (objidx==-1 or j==objidx) {
                #Correct material index in surfs,
                #vector slicing is needed to make a copy!
                
                var newsurf = [];
                foreach (var s; x.surf) {
                    #check for a new material to add
                    var idx = isin(s.mat, newmats);
                                
                    if (idx == -1) {
                        #add to materials
                        append(newmats, s.mat);
                        idx=size(newmats)-1;
                    }
                    
                    append(newsurf, {
                        mat: matoffset + idx,
                        refs: s.refs[:],
                        flag: s.flag
                    });
                }
                
                append(me.obj, {
                    name: x.name,
                    data: x.data,
                    texture: x.texture,
                    loc: x.loc[:],
                    texrep: x.texrep[:],
                    vert: x.vert[:],
                    surf: newsurf }
                );
            }
            j+=1;
        }
        
        #add new materials to list
        foreach (var x; newmats)  
            append(me.mat, ac.mat[x]);

    },
        
    recentercog: func(idx=-1) {
        # recenter to cog plus translation to cog
        # 
        if (size(me.obj)==0 or idx>size(me.obj)-1) 
           return;
        
        if (idx == -1)
          idx=size(me.obj)-1;
        
        var cog = [0,0,0];
        var tmp = [0,0,0];
        var objv = me.obj[idx].vert;
        cog = me.centroid(-1, idx);
        
        me.obj[idx].loc = deepcopy(cog);
        
        # recalc object vertices
        for (var i=0; i<size(objv); i=i+1)
                objv[i] =  sub3d(objv[i], cog);
          
    },

    transobj: func(t, idx=-1) {
        if (size(me.obj)==0 or idx>size(me.obj)-1) 
           return;
        
        if (idx == -1)
          idx=size(me.obj)-1;
          
        if (me.obj[idx].loc == nil) {
          me.obj[idx].loc = [t[0], t[1], t[2]];
        } else {  
          me.obj[idx].loc = add3d(me.obj[idx].loc, t);
        }  
          
    },
    
    packobj: func(idx=-1) {
        # replace the loc vector by an absolute shift
        #
        if (size(me.obj)==0 or idx>size(me.obj)-1) 
           return;
        
        if (idx == -1)
          idx=size(me.obj)-1;
        
        if (equal3d(me.obj[idx].loc, [0,0,0]))
          return;
      
        var objv = me.obj[idx].vert;
        # recalc object vertices
        for (var i=0; i<size(objv); i=i+1)
                objv[i] =  add3d(objv[i], me.obj[idx].loc);
                
        set3d(me.obj[idx].loc, [0,0,0]);
        
    },
        
    centroid: func(dummy=0, iobj=-1) {
      # calculate cog of object index iobj
      # 
      var cog = [0,0,0];
      var objv = me.obj[iobj].vert;
      var l = size(objv);
      
      for (var i=0; i<l; i=i+1)
            cog = add3d(cog, objv[i]);
      
      return [cog[0]/l+me.obj[iobj].loc[0],
              cog[1]/l+me.obj[iobj].loc[1],
              cog[2]/l+me.obj[iobj].loc[2] 
             ];
    },
    
    bbox: func(iobj=-1) {
      # calculate bounding box of object index iobj
      
      var objv = me.obj[iobj].vert;
      var bbmax = deepcopy( objv[0] );
      var bbmin = deepcopy( objv[0] );
      
      foreach (var i; objv) { 
       foreach (var dim; [0,1,2]) {
         bbmax[dim] = (i[dim] > bbmax[dim]) ? i[dim] : bbmax[dim];
         bbmin[dim] = (i[dim] < bbmin[dim]) ? i[dim] : bbmin[dim];
        }
      }
      return {"min": add3d(bbmin, me.obj[iobj].loc),
              "max": add3d(bbmax, me.obj[iobj].loc)
             };
    },
    
    rotobjY: func(alpha, idx=-1) {
      # rotate object index idx about z-axis (in Blender)
      # note that equals y-axis in the AC3D file !
      # positive turn is right turn along z
      
      if (idx==-1) 
            idx = size(me.obj)-1;

      #there seems to be a numerical instability at 45,90,180,.. deg.?
      #this fixes it: 
      alpha = alpha*D2R*1.0001;
      
      var sina = math.sin(alpha);
      var cosa = math.cos(alpha);

      #rotate vertices
      var rot = [];
      foreach (var x; me.obj[idx].vert) {
        append(rot, [
            cosa*x[0]+sina*x[2],
            x[1],
            -sina*x[0]+cosa*x[2] ]);
      }

      #update rotated object vertices
      me.obj[idx].vert = rot;
      return;
    },   
    
    
    inside3: func(idx, p, objidx=-1) {
 
        if (size(idx)!=3)
            die("libac3d.inside: argument 1 must be a triangle");

        var inplane = me.inplane(idx, objidx);

        if (inplane==-1)
            die("libac3d.inside3: all 4 points must lie in the x,y or z plane");

        # select the dimension of the plane in which the 3 points lie
        var dim = otherdims(inplane);
        
        var vert=me.obj[objidx].vert;
    
        tp1 = {x: vert[idx[0]][dim.a], y: vert[idx[0]][dim.b] };
        tp2 = {x: vert[idx[1]][dim.a], y: vert[idx[1]][dim.b] };
        tp3 = {x: vert[idx[2]][dim.a], y: vert[idx[2]][dim.b] };
        ap1 = {x: p[dim.a], y: p[dim.b] };
    
        var b0 = ((tp2.x - tp1.x) * (tp3.y - tp1.y) - (tp3.x - tp1.x) * (tp2.y - tp1.y));
        if (b0 != 0) {
            var b1 = (((tp2.x - ap1.x) * (tp3.y - ap1.y) - (tp3.x - ap1.x) * (tp2.y - ap1.y)) / b0);
            var b2 = (((tp3.x - ap1.x) * (tp1.y - ap1.y) - (tp1.x - ap1.x) * (tp3.y - ap1.y)) / b0);
            var b3 = 1 - b1 - b2;
            return (b1 > 0) and (b2 > 0) and (b3 > 0);     
        } else {   
            return 0;
        }
    },
    
    isconvex3: func(idx, objidx=-1) {
 
        if (size(idx)!=3)
            die("libac3d.isconvex3: argument 1 must be a triangle");

        var inplane = me.inplane(idx, objidx);

        if (inplane==-1)
            die("libac3d.isconvex3: all 3 points must lie in the x,y or z plane");
        
        var vert=me.obj[objidx].vert;
        
        # select the dimension of the plane in which the 3 points lie
        var dim = otherdims(inplane);
    
        p0 = {x: vert[idx[0]][dim.a], y: vert[idx[0]][dim.b] };
        p1 = {x: vert[idx[1]][dim.a], y: vert[idx[1]][dim.b] };
        p2 = {x: vert[idx[2]][dim.a], y: vert[idx[2]][dim.b] };
    
        return ( ((p1.x - p0.x) * (p2.y - p1.y) - (p1.y - p0.y) * (p2.x - p1.x)) )<0;
    },
    
    mergevert: func(verts, objidx=-1) {
    },    
};

# unit tests

var test = func() {
  print("");
  print("######################");
  print(" Unit Tests for ");
  print(" libac3d       ");
  print("######################");
  print("");
  
  #var ac1 = Ac3d.new(getprop("/sim/fg-root") ~ "/Aircraft/working/test.ac");
  #var ac2 = Ac3d.new(getprop("/sim/fg-root") ~ "/Aircraft/working/untitled.ac");
  
  var ac1 = Ac3d.new( getprop("/sim/fg-home") ~ "/Export/untitled.ac");
  var out = Ac3d.new();
  out.addac(ac1);
  #var ac2 = Ac3d.new( getprop("/sim/fg-home") ~ "/Export/untitled2.ac");
  
  
  foreach( var wi; [15,30,45.0,60.0,90.0,125,180.0]) {
    out.addac(ac1);
    out.transobj(bl2ac( [0, 0, wi/18]) );
    out.rotobjY(wi);
    out.rotobjY(wi, out.numobj()-2);
  }
  
  out.addobj();
  var newsurf=[out.addvert([0,1,-2]), out.addvert(1,0,-2), out.addvert(1,1,-2) ];
  out.addsurf(newsurf);
  print("inplane should be 2: ", out.inplane(newsurf) );
      
  out.addobj();
  var newsurf=[];
  append(newsurf, out.addvert([0,1,-2]));
  append(newsurf, out.addvert(0,1,2));
  append(newsurf, out.addvert(3,1,-2));
  
  
  print("inside should be 1: ", out.inside3([0,1,2], [1,1,-1]));
  print("inside should be 0: ", out.inside3([0,1,2], [0,1,10]));
  print("isconvex should be 1 (CW orientation): ", out.isconvex3([0,1,2]) );
  print("isconvex should be 0 (CCW orientation): ", out.isconvex3([2,1,0]) );
  
  print("getclosed3 should be [3,0,1]: ");
  debug.dump(getclosed3(0, [0,1,2,3]));
  
  print("getclosed3 should be [0,1,2]: ");
  debug.dump(getclosed3(1,[0,1,2,3]));
  
  print("getclosed3 should be [2,3,0]: ");
  debug.dump(getclosed3(3,[0,1,2,3]));
  
  out.addsurf(newsurf);
  print("inplane should be 1: ", out.inplane([0,1,2]) );
  
  out.addobj();
  var newsurf=[out.addvert([0,-1,-2]), out.addvert(0,1,2), out.addvert(3,1,-2) ];
  out.fill(newsurf);
  
  print("inplane should be -1:", out.inplane([0,1,2]) );

  debug.dump( ac2bl(out.centroid([0,1,2])) );

  print("equalvert should be 0: ", equalvert([[0,0,0],[0,0,1]], [[0,0,0],[0,0,2]]) );
  print("equalvert should be 1: ", equalvert([[0,0,0],[0,0,1]], [[0,0,0],[0,0,1]]) );
  
  
  # triangulation test structure arrow CW 
  out.addobj();
  out.addvert([10,-1,10]);
  out.addvert([10,-1,-10]);
  out.addvert([-10,-1,-10]);
  out.addvert([-10,-1,10]);
  out.addvert([0,-1,15]);
  #fill the last 5 vertices
  out.fill([0,1,2,3,4]);

  # fill test structure U without triangulation
  out.addobj(); 
  out.addvert([0,-10,0]);
  out.addvert([0,-10,3]);
  out.addvert([1,-10,3]);
  out.addvert([1,-10,1]);
  out.addvert([2,-10,1]);
  out.addvert([2,-10,3]);
  out.addvert([3,-10,3]);
  out.addvert([3,-10,0]);
  #fill the last  vertices
  out.fill([0,1,2,3,4,5,6,7]);
  debug.dump(out.vert());
  
  out.recentercog(-1);
  
  # triangulation test structure U
  out.addobj();
  out.addvert([0,-15,0]);
  out.addvert([0,-15,0.001]);
  out.addvert([1,-15,3]);
  out.addvert([1,-15,1]);
  out.addvert([2,-15,1]);
  out.addvert([2,-15,3]);
  out.addvert([3,-15,0.001]);
  out.addvert([3,-15,0]);
  
  #fill the last vertices CW by triangulation
  out.fill([0,1,2,3,4,5,6,7], tria=1);

  out.recentercog(-1);
  
  print(size(out.obj[-1].vert));
  out.remdup();
  print(size(out.obj[-1].vert));
 
  #out.joinall("joined");
  out.dump();
  out.save( getprop("/sim/fg-home") ~ "/Export/libac3d-unit-tests.ac",3);
  
  print("find the test object index: ",out.addobj("t-e-s-t"), "==", out.find("t-e-s-t"));

};

#io.load_nasal( getprop("/sim/fg-home") ~ "/Nasal/libac3d.nas");
#libac3d.test();
