.util.crash: {[msg]
    .log.fatal msg;
    exit 1;
 };

.util.dropNulls: {[t]
    t where (&/) not null flip t
 };
