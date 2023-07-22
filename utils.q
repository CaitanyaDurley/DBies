.util.crash: {[msg]
    .log.error msg;
    exit 1;
 };

.util.dropNulls: {[t]
    t where (&/) not null flip t
 };
