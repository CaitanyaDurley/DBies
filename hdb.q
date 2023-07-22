\l log.q

.hdb.init: {
    .log.info"**********Starting up*************";
    d: .Q.opt .z.x;
    system"l ", first d`dir;
 };

getDay: {[d]
    .log.info "Getting trade data for date: ", string d;
    select from trades where date = d
 };

.hdb.init[];
