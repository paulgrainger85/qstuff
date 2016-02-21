//keep track of performance of functions
//provide command line arguments to determine whether or not to utilize it
// TODO:
// - Remove incoming calls from system monitor from history
// - Clean up .bmrk.profile function
// - come up with better names for functions

//command line
.bmrk.priv.ARGS:.Q.opt[.z.x]
//Backup dictionary to keep track of previous versions of functions
.bmrk.priv.backup:()!()
.bmrk.priv.ACTIVE:1b
//If the function/argument combo is in this list, then dont track its performance
.bmrk.priv.IGNORE:();

.bmrk.profileHist:([]time:`timestamp$();user:`$();func:`$();args:();runtime:`timespan$();result:();err:())
.bmrk.priv.recentErr:.bmrk.profileHist

.bmrk.revert:{[f] f set .bmrk.priv.backup f}
.bmrk.reset:{.bmrk.revert each key .bmrk.priv.backup}

//@param f
//  @type symbol
//@param vf
//  @type lambda
//@param args
//  @type multiple
//@trackArgs
//  @type boolean
.bmrk.profile:{[f;vf;args;trackArgs]
  t:.z.p;
  //if there is a single argument, or the arg is a string, we need to enlist
  r:@[value;vf,$[(1=count args) or (10h=type args) or (f in `.z.pg`.z.ps) or (99h=type args);enlist args;args];{(0b;x)}];
  argf:(value get f)[1];
  args:$[trackArgs;
    argf!(count argf)#$[(1=count args)|any 99 10h=type args;enlist args;args];
    ()!()];
  `.bmrk.profileHist upsert delta:(.z.P;.z.u;f;args;`timespan$.z.p-t;$[0b~first r;0b;1b];$[0b~first r;last r;(::)]);
  $[0b~first r;
    [`.bmrk.priv.recentErr upsert delta;last r];
    r]
 }

//Function to set up profiling
//@param f
//  @type symbol
//  @desc the function to profile
//@param trackArgs
//  @type boolean
//  @desc set true to track incoming arguments of f. False stores args as ()!()
.bmrk.setFuncProfile:{[f;trackArgs]
  if[not @[{value x;1b};f;{0b}];:.log.warn "Function ",string[f]," does not exist"];
  .bmrk.priv.backup[f]:value f;
  vf:value get f;
  args:";" sv string vf[1];
  f set value "{[",args,"] .bmrk.profile[`",string[f],";",last[vf],";(",args,");",string[trackArgs],"]}";
 }

.bmrk.getErrorDelta:{
  r:select time,alertType:`funcError,misc:{`func`args!(x;y)}'[func;args]from .bmrk.priv.recentErr;
  delete from `.bmrk.priv.recentErr;
  r
 }

//Incoming IPC profiling
.z.pg:{value x};.bmrk.setFuncProfile[`.z.pg;1b]
.z.ps:{value x;};.bmrk.setFuncProfile[`.z.ps;1b]

