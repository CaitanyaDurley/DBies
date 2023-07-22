\l log.q
\l utils.q

.live.init: {
    d: .Q.opt .z.x;
    tbls: {.live.loadFile[`$ "."] `$ x, ".csv"} each d`tables;
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

.live.loadFile:{[loc;f] ("***FF"; enlist csv) 0: ` sv loc,f};

.live.init[];
