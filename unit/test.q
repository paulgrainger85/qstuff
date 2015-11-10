//Usage .tst.test:( function ; params ; expect_result);
.tst.test1:(.c.test;enlist`int$til 10;`int$til 10)
.tst.test2:(.c.add;(10;20);30i)
.res.c:()
{[x]
  .res.c,:{[x;y;z] z~.[x;y;0b]} . .tst[x];
  $[last .res.c;
    -1"test ",string[x]," passed";
    -1"test ",string[x]," failed"];
 }each 1_ key .tst

passRate:sum[.res.c]%count .res.c

-1"Pass rate of ",string[100*passRate],"%";

exit 0


