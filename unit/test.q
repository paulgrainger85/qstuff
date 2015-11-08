.tst.test1:{ .c.test[`int$til 10]~`int$til 10}
.tst.test2:{ .c.add[10;20]=30}

{-1 string[x],"% test success rate";}{100*(sum x)%count x}(1_ .tst)@\:()
exit 0
