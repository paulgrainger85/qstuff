# pgriggy
Note to compile libraries for 32bit kdb+, I needed to download these additional packages

sudo apt-get install lib32z1 lib32ncurses5

sudo apt-get install gcc-multilib

# kdb+ code
bmark.q - a simple profiler for kdb+ function calls

timer.q - a timer library to execute different calls at the given frequency (in ms)

sysmon.q - a system monitor, tracks memory usage. Also links to any process running bmark.q and tracks errors within functions
