args:.Q.opt[.z.x]

SEARCH_STRING:$[not`proc in key args;"$QHOME";first args`proc]

//sysmon.q - a generic system monitor
//things to monitor
//kdb processes - total mem usage, cpu, up time, if process is alive

//table keeping track of all processes
//pid - the process ID
//host - the processes host
//cmd - the command running the process
//mem - current RAM usage
//cpu - current CPU usage
//port - if the process is open on a port insert this

//complete audit trail of procs
procs:([]pid:`long$();user:`$();cmd:();mem:`float$();cpu:`float$();port:`long$();updtime:`timestamp$())


getProcs:{
  p:@[system;"ps aux|grep \"[0-9] ",SEARCH_STRING,"\"";()];
  if[p~();:()];
  p:{{ssr[x;"  ";" "]}/[x]}each p; 
  t:flip`user`pid`cpu`mem`cmd!flip "SJFF*"$/:{x[;0 1 3 5],'enlist each " " sv'10_'x}" " vs' p;
  update port:@[{first "J"$system"lsof -p ",string[x]," -P|grep -o TCP.*LISTEN|grep -o [0-9].*[0-9]"};;0N]each pid from t

 }

.z.ts:{
  `procs upsert update updtime:.z.P from getProcs[]
 }

// ** views **
//Latest state by PID
v_state::select by pid from procs
//Listening on port
v_port::select by pid from procs where not null port
//Dead process
v_dead::select by pid from procs where max[updtime]>(max;updtime)fby pid

