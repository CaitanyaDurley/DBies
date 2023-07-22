.hdb.init: {
    d: .Q.opt .z.x;
    system"l ", first d`dir;
 };

getDay: {[d]
    select from trades where date = d
 };

.hdb.init[];
