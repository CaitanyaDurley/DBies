.log.init: {
    logFile: (-2 _ string .z.f), ".log";
    .log.i.logHandle: @[hopen; hsym `$ logFile; {'"Failed to open log file"}];
    .log.info "**********Starting up*************";
 };

.log.i.root: {[level; msg]
    neg[.log.i.logHandle] "[", level, "] ", msg;
 };

.log.info: .log.i.root["INFO"];
.log.error: .log.i.root["ERROR"];
.log.fatal: .log.i.root["FATAL"];

.log.init[];
