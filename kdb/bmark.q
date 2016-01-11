//keep track of performance of functions
//provide command line arguments to determine whether or not to utilize it

//command line
.bmrk.priv.ARGS:.Q.opt[.z.x]
//Backup dictionary to keep track of previous versions of functions
.bmrk.priv.backup:()!()
.bmrk.priv.ACTIVE:1b
.bmrk.profileHist:([]time:`timestamp$();user:`$();func:`$();args:();runtime:`timespan$();result:();err:())
.bmrk.priv.recentErr:.bmrk.profileHist

.bmrk.revert:{[f] f set .bmrk.priv.backup f}
.bmrk.reset:{.bmrk.revert each key .bmrk.priv.backup}

.bmrk.profile:{[f;vf;args]
  t:.z.p;
  //if there is a single argument, or the arg is a string, we need to enlist
  r:@[value;vf,$[(1=count args) or (10h=type args) or f in `.z.pg`.z.ps;enlist args;args];{(0b;x)}];
  argf:(value get f)[1];
  `.bmrk.profileHist upsert delta:(.z.P;.z.u;f;argf!(count argf)#$[(1=count args)|10h=type args;enlist args;args];`timespan$.z.p-t;$[0b~first r;0b;1b];$[0b~first r;last r;(::)]);
  $[0b~first r;
    [`.bmrk.priv.recentErr upsert delta;last r];
    r]
 }

.bmrk.autoProfile:{[f]
  .bmrk.priv.backup[f]:value f;
  vf:value get f;
  args:";" sv string vf[1];
  f set value "{[",args,"] .bmrk.profile[`",string[f],";",last[vf],";(",args,")]}";
 }

.bmrk.getErrorDelta:{
  r:select time,alertType:`funcError,misc:{`func`args!(x;y)}'[func;args]from .bmrk.priv.recentErr;
  delete from `.bmrk.priv.recentErr;
  r
 }

//Incoming IPC profiling
.z.pg:{value x};.bmrk.autoProfile`.z.pg
.z.ps:{value x;};.bmrk.autoProfile`.z.ps

