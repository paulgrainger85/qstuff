// ***********************************
// * sysmon.q - a kdb system monitor *
// ***********************************
// Monitors all processes running on local host and keeps track of their current usage
// Links with bmark.q script to utilizing error tracking table
//
// **********************************************
// REQUIRED ARGS
//   -config CONFIG_FILE
//
// OPTIONAL ARGS
//   -freq UPDATE_FREQ
// **********************************************
// DEPENDENCIES
//   timer.q
//
// TODO(s):
// - Allow process to monitor remote hosts
// - Connect to processes which are open on a port
// - library for kdb processes to run santiy checks on data
// - Some sort of notifications if certain conditions met (process dead, high memory/cpu, OOM about to go on killing spree)
// - Log file to enable replay in case of crash
// - Some simple html5 client which can display the data?
// - Run lsof in background (maybe spawn C lib which periodically returns data to kdb)
// ************************************************

// ** Schemas **
sysmon:([name:`$()]user:`$();pid:`int$();cmd:();host:`$();port:`int$();handle:`int$());
memMonitor:([]name:`sysmon$`$();time:`timestamp$();mem:`long$())
alerts:([]name:`sysmon$`$();time:`timestamp$();alertType:`$();misc:())

// ** Globals **
.sysm.priv.ARGS:.Q.opt[.z.x]
if[not all `config in key .sysm.priv.ARGS;
  .log.err "Missing required arguments: -config";
  exit 1]

.sysm.priv.CONFIG:("S**";enlist",")0:first hsym`$.sysm.priv.ARGS[`config];
.sysm.priv.FREQ:$[`freq in key .sysm.priv.ARGS;first "J"$.sysm.priv.ARGS`freq;60000] //frequency of monitor


// ** Functions **
.sysm.init:{
  //read from config file
  procs:.sysm.priv.CONFIG[`name]!hsym`$":" sv'flip .sysm.priv.CONFIG`host`port;
  `sysmon upsert select name,`$host,"I"$port from .sysm.priv.CONFIG;
  //open a connection to each process in the config file
  update handle:@[hopen;;0Ni]each procs[name]from `sysmon;
  .sysm.getProcMeta each exec name from sysmon;
 }

//Called on initiaization to populate sysmon table
.sysm.getProcMeta:{[id]
  h:neg first exec handle from sysmon where name=id;
  if[not null h;
    h({neg[.z.w](`.sysm.initCallback;x;.z.u;.z.i;" " sv .z.X)};id);
  ]
 }

.sysm.reconnect:{
  if[count c:select from sysmon where null handle;
    update handle:@[hopen;;0Ni]each{hsym`$x,":",y}'[string host;string port]from `sysmon where handle in exec handle from c;
    if[count active:select from c where name in exec name from sysmon where not null handle;
      .sysm.getProcMeta each exec name from active;
      .sysm.printInfo active;
     ]
  ]
 }

.sysm.printInfo:{[t]
  .log.info "Connected to the following processes:\n",.Q.s t;
 }

// ** Monitoring functions **
//Memory
.sysm.monitorMem:{
  {[h;name]
    neg[h]({neg[.z.w](`.sysm.memCallback;x;.Q.w[]`used)};name)
   } .' flip value exec handle,name from sysmon where not null handle;
 }

//Function status from bmark.q
.sysm.checkForErrors:{
  {[h;name]
    neg[h]({neg[.z.w](`.sysm.errorCallback;$[@[get;`.bmrk.priv.ACTIVE;0b];.bmrk.getErrorDelta[];()];x)};name)
  } .' flip value exec handle,name from sysmon where not null handle;
 }

// *** Callbacks ***
.sysm.initCallback:{[x;u;pid;cmd]
  `sysmon upsert `name`user`pid`cmd!(x;u;pid;cmd)
 }

.sysm.memCallback:{[id;m]
  `memMonitor upsert `name`time`mem!(id;.z.P;m)
 }

.sysm.errorCallback:{[err;id]
  if[not count err;:()];
  .log.warn string[count err]," new error(s) detected in process ",string id;
  `alerts upsert update name:id from err
 }

// ** .z handlers **
//close handler
.sysm.z.pc:{
  n:first exec name from sysmon where handle=x;
  .log.warn "Process ",string[n]," has closed";
  update handle:0Ni from `sysmon where handle=x;
  `alerts upsert(n;.z.P;`close;()!())
 }

.z.pc:{.sysm.z.pc[x]}
//set up timers
.timer.addTimer[`memMonitor;(`.sysm.monitorMem;::);5000]
.timer.addTimer[`reconnect;(`.sysm.reconnect;::);5000]
.timer.addTimer[`errors;(`.sysm.checkForErrors;::);5000]

.sysm.init[]
