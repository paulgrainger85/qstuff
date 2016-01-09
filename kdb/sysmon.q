// ***********************************
// * sysmon.q - a kdb system monitor *
// ***********************************
// Monitors all processes running on local host and keeps track of their current usage
//
// REQUIRED ARGS
// -------------
// OPTIONAL ARGS
// -------------
// -proc PROCESS_STRING
// -log REPLAY_LOG 
//
// TODO(s):
// - Allow process to monitor remote hosts
// - OOM style killer
// - Connect to processes which are open on a port
// - library for kdb processes to run santiy checks on data
// - Some sort of notifications if certain conditions met (process dead, high memory/cpu, OOM about to go on killing spree)
// - Log file to enable replay in case of crash
// - Some simple html5 client which can display the data? 
// - Run lsof in background (maybe spawn C lib which periodically returns data to kdb)
// ************************************************

// ** Schemas **
tracking:([pid:`long$()]user:`$();cmd:();port:`long$();handle:`int$());
trackingHist:([]pid:`tracking$`long$();time:`timestamp$();mem:`float$();cpu:`float$())

args:.Q.opt[.z.x]

SEARCH_STRING:$[not`proc in key args;"$QHOME";first args`proc]

//sysmon.q - a generic system monitor
//things to monitor
//kdb processes - total mem usage, cpu, up time, if process is alive

//table keeping track of all processes
//pid - the process ID
//cmd - the command running the process
//mem - current RAM usage
//cpu - current CPU usage
//port - if the process is open on a port insert this

//TODO: Consider adding the following stats
// open file handles
// host
// if able to connect to port:
// -- monitor output of .z.W
// -- time taken for a response 

//Get all active processes
getProcs:{
  p:@[system;"ps aux|grep \"[0-9] ",SEARCH_STRING,"\"";()];
  if[p~();:()];
  p:{{ssr[x;"  ";" "]}/[x]}each p; 
  t:flip`user`pid`cpu`mem`cmd!flip "SJFF*"$/:{x[;0 1 3 5],'enlist each " " sv'10_'x}" " vs' p;
  update port:@[{first "J"$system"lsof -p ",string[x]," -P|grep -o TCP.*LISTEN|grep -o [0-9].*[0-9]"};;0N]each pid from t
 }

connect:{[x] @[hopen;;0Ni]each`$"::",string x}

//.z handlers 
.z.ts:{
  p:update time:.z.P from getProcs[];
  `tracking upsert select pid,user,cmd,port from p;
  `trackingHist upsert select pid,time,mem,cpu from p;
 }

//close handle
.z.pc:{}


