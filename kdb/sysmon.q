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
sysmon:([name:`$()]user:`$();pid:`int$();cmd:();host:`$();port:`int$();handle:`int$();active:`boolean$());
memMonitor:([]name:`sysmon$`$();time:`timestamp$();mem:`long$();percentOfWmax:`float$();percentOfSystem:`float$())
alerts:([]name:`sysmon$`$();time:`timestamp$();alertType:`$();misc:())

// ** Globals **
.sysm.priv.ARGS:.Q.opt[.z.x]
if[not all `config in key .sysm.priv.ARGS;
  .log.err "Missing required arguments: -config";
  exit 1]

.sysm.priv.CONFIG:("S**FF";enlist",")0:first hsym`$.sysm.priv.ARGS[`config];
.sysm.priv.FREQ:$[`freq in key .sysm.priv.ARGS;first "J"$.sysm.priv.ARGS`freq;60000] //frequency of monitor


// ** Functions **
.sysm.init:{
  //read from config file
  procs:.sysm.priv.CONFIG[`name]!hsym`$":" sv'flip .sysm.priv.CONFIG`host`port;
  `sysmon upsert select name,`$host,"I"$port from .sysm.priv.CONFIG;
  //open a connection to each process in the config file
  update handle:@[hopen;;0Ni]each procs[name],active:1b from `sysmon;
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
    neg[h]({neg[.z.w](`.sysm.memCallback;x;.Q.w[])};name)
   } .' flip value exec handle,name from sysmon where not null handle,active;
 }

//Function status from bmark.q
.sysm.checkForErrors:{
  {[h;name]
    neg[h]({neg[.z.w](`.sysm.errorCallback;$[@[get;`.bmrk.priv.ACTIVE;0b];.bmrk.getErrorDelta[];()];x)};name)
  } .' flip value exec handle,name from sysmon where not null handle,active;
 }

//supress alerts from a process
.sysm.sleep:{[id] update active:0b from `sysmon where name=id;.log.info "Supressing alerts from ",string id}
//re-enable alerts for a process
.sysm.wakeup:{[id] update active:1b from `sysmon where name=id;.log.info "Enabling alerts from ",string id}

// *** Callbacks ***
.sysm.initCallback:{[x;u;pid;cmd]
  `sysmon upsert `name`user`pid`cmd!(x;u;pid;cmd)
 }

.sysm.memCallback:{[id;m]
  `memMonitor upsert `name`time`mem`percentOfWmax`percentOfSystem!(id;.z.P;m`used;$[0<>m`wmax;100*(%). m`used`wmax;0n];100*(%). m`used`mphy);
  .sysm.checkMemThresholds[id]
 }

//if thresholds are defined within the config, then run check to ensure that we are not breaching them
//to stop spamming of alerts, only alert if this alert hasnt been sent in the past 10 mins (maybe make this configurable)
.sysm.checkMemThresholds:{[id]
  if[(count w:select from .sysm.priv.CONFIG where name=id,not null wmax_t)&0D00:10:00<.z.P-0|max exec time from alerts where name=id,alertType=`wmax_breach;
    if[count t:select from (-1#select from memMonitor where name=id)where percentOfWmax>first w`wmax_t;
      .log.warn "Process ",string[id]," has breached WMAX limit ",string[last t`percentOfWmax],"%";
      `alerts upsert `name`time`alertType`misc!(id;.z.P;`wmax_breach;`mem`percentOfWmax#flip t)];
   ];
  if[(count w:select from .sysm.priv.CONFIG where name=id,not null sysmem_t)&0D00:10:00<.z.P-0|max exec time from alerts where name=id,alertType=`sys_mem_breach;
    if[count t:select from (-1#select from memMonitor where name=id)where percentOfSystem>first w`sysmem_t;
      .log.warn "Process ",string[id]," has breached system limit ",string[last t`percentOfSystem],"%";
      `alerts upsert `name`time`alertType`misc!(id;.z.P;`sys_mem_breach;`mem`percentOfSystem#flip t)];
   ];
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
