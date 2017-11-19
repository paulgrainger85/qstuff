generateOrder:{

  tab:first `cxlOrder`modOrder`newOrder@first where raze 1 4 9>\:1?10;
  px:first 1?10+0.01*til 100;
  side:first "12"@first 1?2;
  if[tab in `modOrder`newOrder;
    currPx:$[side="1";exec min price from orderState where side="2";exec max price from orderState where side="1"];
    $[currPx in 0w -0w;1b;(side="1")&px>currPx;px:currPx;(side="2")&px<currPx;px:currPx;()];
    ];
  if[tab=`newOrder;
    .match.upd.newOrder -1#value`newOrder upsert enlist`instrument`side`clOrdID`orderQty`price!(`ABC;side;10?.Q.a,.Q.A;first 1?1000;px)];
  if[tab=`modOrder;
    id:first 1?exec orderID from orderState where qty>0;
    if[null id;:()];
    .match.upd.modOrder -1#value `modOrder upsert update price:px,orderQty:100+abs orderQty+(first 1?1 -1)*100,orderID:id from select from newOrder where clOrdID like exec first clOrdID from newOrderAck where orderID in id];
  if[tab=`cxlOrder;
    id:first 1?exec orderID from orderState where qty>0;
    if[null id;:()];
    .match.upd.cxlOrder -1#value`cxlOrder upsert select instrument,orderID:id,clOrdID from newOrder where clOrdID like exec first clOrdID from newOrderAck where orderID in id];

 }


.z.ts:{generateOrder[]}

\t 10
