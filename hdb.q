\l log.q

.hdb.init: {
    .log.info"**********Starting up*************";
    d: .Q.opt .z.x;
    system"l ", first d`dir;
 };

getDay: {[t; d]
    .log.info "Getting trade data for date: ", string d;
    select from t where date = d
 };

.hdb.init[];
