\l log.q
\l utils.q

.live.init: {
    d: .Q.opt .z.x;
    .live.validateArgs d;
    tradeTbls: {.live.loadFile[`$ ":./"] `$ x, ".csv"} each d`tables;
    tradeTbls: .util.dropNulls each tradeTbls;
    .log.info "Computing HLOC for tables...";
    hlocTbls: .live.getHLOC each tradeTbls;
    joinedTbl: .live.joinTbls . @[; hlocTbls] each (first; last);
    tblLookup: .live.compareTbls joinedTbl;
    .log.info "Done!";
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

.live.joinTbls: {[t1; t2]
    rename:{[t;tname] xcol[; t] `sym,`$ (tname, "_"),/: string 1_cols t};
    rename[t1;"t1"] uj rename[t2;"t2"]
 };

.live.compareTbls: {[t]
    t: {![x; (); enlist[`sym]!enlist`sym; enlist[`$y, "_spread"]!enlist (abs; (-; `$y, "_open"; `$ y, "_close"))]}/[t; string `t1`t2];
    t1s: select tbl: `t1 by sym from t where (not null t1_spread), t1_spread = t1_spread & t2_spread;
    t2s: keys[t] except keys t1s;
    t1s, ([sym: t2s] tbl: count[t2s]#`t2)
 };

.live.init[];
