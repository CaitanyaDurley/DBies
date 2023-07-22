\l log.q
\l utils.q

.live.init: {
    d: .Q.opt .z.x;
    d: .live.validateArgs d;
    out: $[`date in key d;
        .live.runRemote d`date;
        .live.runLocal d`tables
    ];
    / .live.saveHDB out;
    .log.info "Done!";
    / exit 0;
 };

.live.runLocal: {[tbls]
    tradeTbls: {.live.loadFile[`$ ":./"] `$ x, ".csv"} each tbls;
    .live.runGeneric tradeTbls
 };

.live.runRemote: {[date]
    // open connections to hdb1 and hdb2
    h1: .util.connect `::5001;
    h2: .util.connect `::5002;
    t1: h1 (`getDay; date);
    t2: h2 (`getDay; date);
    .live.runGeneric (t1; t2)
 };

.live.runGeneric: {[tradeTbls]
    hlocTbls: .live.getHLOC each tradeTbls;
    joinedTbl: .live.joinTbls . @[; hlocTbls] each (first; last);
    tblLookup: .live.compareTbls joinedTbl;
    .live.buildBestTbl[tradeTbls; tblLookup]
 }

/ Validates user supplied args dict
/ @param d (Dictionary)
.live.validateArgs: {[d]
    if[`date in key d;
        / in hdb mode
        :@[d; `date; "D"$; {.util.crash "Please pass a valid date"}]
    ];
    / if we get here, we're in local csv mode
    if[not `tables in key d;
        .util.crash "Please specify the tables"
    ];
    if[2 <> count d`tables;
        .util.crash "Specify two tables"
    ];
    :d
 };

/ Reads in a trade csv
/ @param loc (Symbol) e.g. `:/abc/def
/ @param f (Symbol) e.g. mydata.csv
/ @returns (Table)
.live.loadFile: {[loc; f]
    .log.info "Reading file ", string[f], " from location: ", string loc;
    ("PSCFF"; enlist csv) 0: ` sv loc,f
 };

/ Compute the high, low, open & close by sym
/ @param t (Table) ONE DAY's worth of trade data
/ @returns (Table) keyed by sym
.live.getHLOC:{[t]
    .log.info "Computing HLOC for tables...";
    t: .util.dropNulls t;
    select high: max price, low: min price, open: first price, close: last price by sym from t
 };

/ Joins two HLOC tbls
/ @param t1 (Table) ONE DAY's worth of hloc data
/ @param t2 (Table) ONE DAY's worth of hloc data
/ @returns (Table) with cols renamed e.g. price -> t1_price, t2_price
.live.joinTbls: {[t1; t2]
    rename:{[t;tname] xcol[; t] `sym,`$ (tname, "_"),/: string 1_cols t};
    rename[t1;"t1"] uj rename[t2;"t2"]
 };

/ Given a joined hloc tbl, choose the table (by sym) with the smallest open-close spread
/ @param t (Table) Output from .live.joinTbls
/ @returns (Table) a lookup from sym (e.g. AAPL) to table number (e.g. 0)
.live.compareTbls: {[t]
    t: {![x; (); enlist[`sym]!enlist`sym; enlist[`$y, "_spread"]!enlist (abs; (-; `$y, "_open"; `$ y, "_close"))]}/[t; string `t1`t2];
    t1s: 0! select tbl: 0 by sym from t where (not null t1_spread), t1_spread = t1_spread & t2_spread;
    t2s: (exec sym from t) except t1s`sym;
    t1s, ([] sym: t2s; tbl: count[t2s]#1)
 };

/ Given a lookup from sym to table number, take trade data from the relevant table (by sym)
/ @param tradeTbls (List) i.e. (t1; t2)
/ @param tblLookup (Table) output from .live.compareTbls
/ @returns (Table) The "best" trade data
.live.buildBestTbl: {[tradeTbls; tblLookup]
    tblLookup: exec sym by tbl from tblLookup;
    raze {[t; syms] select from t where sym in syms}'[tradeTbls key tblLookup; value tblLookup]
 };

.live.init[];
