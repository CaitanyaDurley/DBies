\l log.q
\l utils.q

.live.init: {
    .log.info"**********Starting up*************";
    d: .Q.opt .z.x;
    d: .live.validateArgs d;
    $[`date in key d;
        .live.runRemote d`date;
        .live.runLocal d`tables
    ];
    .log.info "Done!";
    / exit 0;
 };

/ For running against local CSVs
/ @param tbls (String List) e.g. ("tab1"; "tab2")
.live.runLocal: {[tbls]
    tradeTbls: {.live.loadFile[`$ ":./"] `$ x, ".csv"} each tbls;
    .live.runGeneric[tradeTbls; `];
 };

/ For running against remote HDBs
/ @param date (Date)
.live.runRemote: {[date]
    // open connections to hdb1 and hdb2
    h1: .util.connect `::5001;
    h2: .util.connect `::5002;
    tradeTbls: (h1; h2) @\: (`getDay; `trades; date);
    quoteTbls: (h1; h2) @\: (`getDay; `quotes; date);
    .live.runGeneric[tradeTbls; quoteTbls];
 };

/ Given two trade/quote tables, compare and build the best one
/ @param tradeTbls (List) two trade data tables
/ @param tradeTbls (List) two quote data tables
.live.runGeneric: {[tradeTbls; quoteTbls]
    tradeTbls: .util.dropNulls each tradeTbls;
    hlocTbls: .live.getHLOC each tradeTbls;
    joinedTbl: .live.joinTbls . @[; hlocTbls] each (first; last);
    tblLookup: .live.compareTbls joinedTbl;
    / BEGIN EXTENSION QUESTIONS
    .live.buildBestTbl[`summary; hlocTbls; tblLookup]
    .live.buildPercDiff hlocTbls;
    / END EXTENSION QUESTIONS
    .live.buildBestTbl[`trades; tradeTbls; tblLookup];
    if[not quoteTbls ~ `;
        .live.buildBestTbl[`quotes; quoteTbls; tblLookup]
    ];
    .live.saveHDB[];
 };

.live.buildPercDiff: {[hlocTbls]
    hlocTbls: `sym xkey/: hlocTbls;
    percDiff: 100 * (.[-] hlocTbls) % first hlocTbls;
    `percDiff set 0! percDiff
 };

/ Validates user supplied args dict
/ @param d (Dictionary)
.live.validateArgs: {[d]
    if[`date in key d;
        / in hdb mode
        :@[d; `date; '[$["D"]; first]]
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
    .log.info "Computing HLOC...";
    0! select high: max price, low: min price, open: first price, close: last price by sym from t
 };

/ Joins two HLOC tbls
/ @param t1 (Table) ONE DAY's worth of hloc data
/ @param t2 (Table) ONE DAY's worth of hloc data
/ @returns (Table) with cols renamed e.g. price -> t1_price, t2_price
.live.joinTbls: {[t1; t2]
    .log.info "Joining HLOC tables...";
    rename:{[t;tname] xcol[; t] `sym,`$ (tname, "_"),/: string 1_cols t};
    .[uj] `sym xkey/: (rename[t1; "t1"]; rename[t2; "t2"])
 };

/ Given a joined hloc tbl, choose the table (by sym) with the smallest open-close spread
/ @param t (Table) Output from .live.joinTbls
/ @returns (Table) a lookup from sym (e.g. AAPL) to table number (e.g. 0)
.live.compareTbls: {[t]
    .log.info "Comparing HLOC tables...";
    t: {![x; (); enlist[`sym]!enlist`sym; enlist[`$y, "_spread"]!enlist (abs; (-; `$y, "_open"; `$ y, "_close"))]}/[t; string `t1`t2];
    t1s: 0! select tbl: 0 by sym from t where (not null t1_spread), t1_spread = t1_spread & t2_spread;
    t2s: (exec sym from t) except t1s`sym;
    t1s, ([] sym: t2s; tbl: count[t2s]#1)
 };

/ Given a lookup from sym to table number, take trade data from the relevant table (by sym)
/ @param tbls (List) i.e. (t1; t2), either two trade datasets or two quote datasets
/ @param tblLookup (Table) output from .live.compareTbls
.live.buildBestTbl: {[tName; tbls; tblLookup]
    .log.info "Building best table...";
    tblLookup: exec sym by tbl from tblLookup;
    tName set raze {[t; syms] select from t where sym in syms}'[tbls key tblLookup; value tblLookup]
 };

.live.saveHDB: {
    / we always save down a trades table
    d: exec `date$first time from `trades;
    {[d; tName]
        .log.info "Saving down ", string tName;
        .Q.dpft[`:hdb; d; `sym; tName];
    }[d] each tables[];
 };

.live.init[];
