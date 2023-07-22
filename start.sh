#!/bin/bash

q makedb.q
nohup q hdb.q -dir "hdb1"
nohup q hdb.q -dir "hdb2"
q livelive.q -tables t1 t2 # for csv
q livelive.q -date 2014.05.01 # for remote
