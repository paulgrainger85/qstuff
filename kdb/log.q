// *****************************
// * log.q - a logging library *
// *****************************
//Log constants
.log.priv.LEVELS:`debug`info`warning`error
.log.priv.COLORS:(!) . flip(
  (`error;"\033[0;31m"); //red
  (`warning;"\033[0;33m"); //yellow
  (`info;"\033[0;37m"); //white
  (`debug;"\033[0;36m") //blue
 )
.log.priv.L:`info //default level

//Private log functions
.log.priv.time:{string[.z.D]," ",string `second$.z.T}
.log.priv.str:{[level;m] .log.priv.COLORS[level],"[",.log.priv.time[]," ",string[.z.u]," ",string[level],"] ",m,"\033[0;37m"}
.log.priv.m:{[level;m] if[(>=) . .log.priv.LEVELS?level,.log.priv.L; -1 .log.priv.str[level;m]]}

//User functions
.log.debug:.log.priv.m[`debug]
.log.info:.log.priv.m[`info]
.log.warn:.log.priv.m[`warning]
.log.err:.log.priv.m[`error]



