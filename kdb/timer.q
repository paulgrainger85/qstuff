
.timer.priv.timers:([]name:`$();cmd:();freq:`long$();nextExec:`timestamp$())
.timer.priv.err:([]name:`$();time:`timestamp$();err:())

.timer.addTimer:{[id;cmd;freq]
  `.timer.priv.timers upsert `name`cmd`freq!(id;cmd;freq);
  update nextExec:.z.P+`long$freq*1e6 from `.timer.priv.timers where name=id;
  .log.info "Added timer ",string[id]," to run every ",string[freq],"ms";
 }

.timer.dropTimer:{[id]
  .log.info "Dropping timer ",string id;
  delete from  `.timer.priv.timers where name=id;
 }

.timer.exec:{
  if[count n:exec name from .timer.priv.timers where nextExec<=.z.P;
    {[f;name] @[value;f;{[name;err] .timer.err[name;err]}[name]]} .' flip value exec cmd,name from .timer.priv.timers where name in n;
    update nextExec:nextExec+`long$freq*1e6 from `.timer.priv.timers where name in n]
 }

.timer.err:{[name;err]
   .log.err "Timer error: ",string[name]," : ",err;
   `.timer.priv.err upsert (name;.z.P;err)
  }

.z.ts:{.timer.exec[]}
\t 100
