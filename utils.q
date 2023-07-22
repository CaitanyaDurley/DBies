.util.crash: {[msg]
    .log.error msg;
    exit 1;
 };

.util.dropNulls: {[t]
    t where (&/) not null flip t
 };

.util.connect: {[addr]
    @[hopen; addr; .log.error["failed to connect"]]
 };
