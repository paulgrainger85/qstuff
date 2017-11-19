//SCHEMAS
newOrderAck:([]time:`timestamp$();clOrdID:();orderID:`u#`long$();instrument:`g#`$();side:`char$();orderQty:`long$();price:`float$();seqNum:`u#`long$())
modOrderAck:([]time:`timestamp$();clOrdID:();orderID:`long$();instrument:`g#`$();side:`char$();orderQty:`long$();price:`float$();leavesQty:`long$();seqNum:`u#`long$())
cxlOrderAck:([]time:`timestamp$();clOrdID:();orderID:`u#`long$();instrument:`g#`$();cxlQty:`long$();seqNum:`u#`long$())

fillAck:([]time:`timestamp$();orderID:`long$();execID:`long$();instrument:`g#`$();side:`char$();price:`float$();lastPx:`float$();lastQty:`long$();seqNum:`u#`long$();aggressor:`boolean$())

orderState:([orderID:`u#`long$()]side:`char$();qty:`long$();price:`float$();seqNum:`long$();instrument:`g#`$())

//GLOBALS
.match.global.SEQ_NUM:0 //unique sequence number of messages used to determine order priority
.match.global.MATCH_NO:0 //used to link executions
.match.global.ORDER_ID:0 //used to uniquely identify orders


//TEST DATA
//newOrder:enlist`instrument`side`clOrdID`orderQty`price!(`ABC;"1";"test123";1000;10f)
//newOrder,:enlist`instrument`side`clOrdID`orderQty`price!(`ABC;"2";"test1234";500;10f)
//modOrder:enlist`instrument`side`clOrdID`orderID`price`orderQty!(`ABC;"1";"test123";1;11f;450)
//cxlOrder:enlist`instrument`orderID`clOrdID!(`ABC;1;"test123")


.match.upd.newOrder:{
//add seqnum, update time to current engine time, add unique orderID
  r:update time:.z.p from .match.addOrderID .match.addSeqNum x;
//update order state with this new order
  `orderState upsert 1!select orderID,side,qty:orderQty,price,seqNum,instrument from r;
//add to the newOrderAck table
  `newOrderAck upsert select time,clOrdID,orderID,instrument,side,orderQty,price,seqNum from r;
//run matching logic
  .match.run each r
 }


.match.upd.modOrder:{
//pull existing data from orderState
  r:update time:.z.p from x lj `orderID`side`prev_qty`prev_price xcol orderState;
//if order has already been filled, or orderID does not exist, reject this
  if[(0=exec last qty from orderState where orderID in x`orderID) or not any x[`orderID]in exec orderID from orderState;:()]; //TODO add reject messages
//if the price has changed, or if the qty has increased,  update the priority (i.e. goes to the back of the queue)
  if[count select from r where (price<>prev_price)or orderQty>prev_qty;r:.match.addSeqNum[r]];
//now update the order state
  `orderState upsert 1!select orderID,side,qty:orderQty,price,seqNum from r;
//update modOrderAck. For this message, increase the seqNum so we have a true representation of the events
  `modOrderAck upsert select time,clOrdID,orderID,instrument,side,orderQty,price,seqNum from .match.addSeqNum[r];
//run matching logic
  .match.run each r
 }

.match.upd.cxlOrder:{
  if[not any x[`orderID]in exec orderID from orderState;:()]; //TODO add reject message
  r:update time:.z.p from x lj `orderID`cxlQty xcol enlist[`qty]#/:orderState;
//set qty to 0 for this order
  update qty:0 from `orderState where orderID in x`orderID;
//update the cancel acknowledge table
  `cxlOrderAck upsert select time,clOrdID,orderID,instrument,cxlQty,seqNum from .match.addSeqNum[r];
//no need to run matching logic on cancels
 }


.match.run:{
  r:.match.matchOrders x;
  if[count r;
    r:.match.fillOrders[x;0!r];
//update the current order state. Upsert in the latest leaves qty by orderID
    `orderState upsert(1!select orderID,qty:leavesQty from r),([orderID:enlist x`orderID]qty:enlist last r`aggLeavesQty);
    `fillAck upsert .match.createFillMsg[x;r]];
 }

.match.matchOrders:{
//hhe seqNum provides the time-order priority of the messages
  matches:`seqNum xasc select from orderState where instrument=x[`instrument],qty>0,side=("12"!"21")[x`side],?[side="1";price>=x`price;price<=x`price];
//if there are no matches, do nothing
  if[not count matches;:()];
//sort by price, based on side
//first update the price to be the min of price and matched price, to preserve order priority
  matches:update matchPrice:?["2"=x`side;price|x[`price];price&x`price]from matches;
  matches:$[x[`side]="1";`matchPrice xasc matches;`matchPrice xdesc matches];
  matches

 }


.match.fillOrders:{[x;matches]
  r:enlist[x]uj matches;
  r:update leavesQty:0|qty-prev aggLeavesQty from update aggLeavesQty:0|(fills orderQty)-sums qty from r;
//only return orders which can be filled
  select from r where qty>leavesQty
 }

//aggOrder - the aggressor order initiating the trade
//orders - the order or orders which cross against the aggressor
.match.createFillMsg:{[aggOrder;orders]
//the transaction time will be the time of the aggressor order
  ts:aggOrder`time;
  fillMsg:update time:ts from select orderID,instrument,side,price,lastPx:matchPrice,lastQty:qty-leavesQty from orders;
//add the execID
  fillMsg:.match.addExecID[fillMsg];
//double each message to add the opposite side
  fillMsg:update orderID:aggOrder[`orderID],price:aggOrder[`price],side:("12"!"21")[side],aggressor:1b from (ungroup 2#''fillMsg)where 1=i mod 2;
//add the seqNum
  fillMsg:.match.addSeqNum[fillMsg];
  fillMsg

 }

.match.addExecID:{[tab]
  n:count tab;
  orig:.match.global.MATCH_NO;
  .match.global.MATCH_NO+:n;
  update execID:(orig+1)+til count i from tab
 }

.match.addSeqNum:{[tab]
  n:count tab;
  orig:.match.global.SEQ_NUM;
  .match.global.SEQ_NUM+:n;
  update seqNum:(orig+1)+til count i from tab
 }

.match.addOrderID:{[tab]
  n:count tab;
  orig:.match.global.ORDER_ID;
  .match.global.ORDER_ID+:n;
  update orderID:(orig+1)+til count i from tab
 }

