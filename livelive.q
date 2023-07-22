\l log.q
\l utils.q

.live.init: {
    d: .Q.opt .z.x;
    tbls: {.live.loadFile[`$ ":./"] `$ x, ".csv"} each d`tables;
    .log.info "Computing HLOC for tables...";
    tbls: .live.getHLOC each tbls;
    / exit 0;
 };

.live.validateArgs: {[d]
    if[not `tables in key d;
        .util.crash "Please specify the tables"
    ];
    if[2 <> count d`tables;
        .util.crash "Specify two tables"
    ];
 };

.live.loadFile: {[loc; f]
    .log.info "Reading file ", string[f], " from location: ", string loc;
    ("PSCFF"; enlist csv) 0: ` sv loc,f
 };

.live.getHLOC:{[t]
    select high: max price, low: min price, open: first price, close: last price by sym from t
 };

.live.init[];
