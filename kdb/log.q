// *****************************
// * log.q - a logging library *
// *****************************
// *** Functions ***
// .log.level - sets the logging level
// .log.debug - prints log message as a debug message
// .log.info - prints log message as an info message
// .log.warn - prints log message as a warning message
// .log.err - prints log message as an error
// .log.enableColor - turns colourful logging on or off
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
.log.priv.COLORS_ACTIVE:1b

//Private log functions
.log.priv.time:{string[.z.D]," ",string `second$.z.T}
.log.priv.str:{[level;m] $[.log.priv.COLORS_ACTIVE;.log.priv.COLORS[level];""],"[",.log.priv.time[]," ",string[.z.u]," ",string[level],"] ",m,$[.log.priv.COLORS_ACTIVE;"\033[0;37m";""]}
.log.priv.m:{[level;m] if[(>=) . .log.priv.LEVELS?level,.log.priv.L; $[level in `debug`info;-1;-2] .log.priv.str[level;m]]}

//User functions
//Sets logging level
.log.level:{[l] if[l in .log.priv.LEVELS;.log.priv.L:l]}
//main functions to write to logs
.log.debug:.log.priv.m[`debug]
.log.info:.log.priv.m[`info]
.log.warn:.log.priv.m[`warning]
.log.err:.log.priv.m[`error]
//Turns on colourful logging
.log.enableColor:{[onOff] .log.priv.COLORS_ACTIVE:$[onOff=`on;1b;0b]}
//Sets logging level
.log.level:{[l] if[l in .log.priv.LEVELS;.log.priv.L:l]}
