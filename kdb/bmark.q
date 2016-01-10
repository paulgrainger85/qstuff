//keep track of performance of functions
.bmrk.priv.backup:()!()

.bmrk.revert:{[f] f set .bmrk.priv.backup f}
.bmrk.funcs:([]time:`timestamp$();user:`$();func:`$();args:();runtime:`timespan$();result:();err:())

.bmrk.profile:{[f;vf;args]
  t:.z.p;
  r:.[vf;$[1=count args;enlist args;args];{(0b;x)}];
  `.bmrk.funcs upsert(.z.P;.z.u;f;(value get f)[1]!args;`timespan$.z.p-t;$[0b~first r;0b;1b];$[0b~first r;last r;(::)]);
  $[0b~first r;last r;r]
 }

.bmrk.autoProfile:{[f]
  .bmrk.priv.backup[f]:value f;
  vf:value get f;
  args:";" sv string vf[1];
  f set value "{[",args,"] .bmrk.profile[`",string[f],";",last[vf],";(",args,")]}";
 }

//some tests for now
.test.f:{1+x+y}
.bmrk.autoProfile`.test.f

.test.g:{.log.err "this is an error message"; x+y}
.bmrk.autoProfile`.test.g

.test.f2:{[param1;param2] .log.warn "warning"; (param1;param2)}
.bmrk.autoProfile`.test.f2
