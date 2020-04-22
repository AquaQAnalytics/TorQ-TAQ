hdbdir:hsym`$getenv[`KDBHDB],"/"
homedir:hsym `$getenv[`TORQHOME]
tempdbdir:hsym `$getenv[`TORQTAQTEMPDB]
pardir:`$"/" sv (string tempdbdir;string .z.d)
quotedir:`$"/" sv (string pardir;"quote";"")

/-this empty schema doesnt work yet
/empty:([]sym:`$();ticktime:"p"$();exch:"s"$();bid:"f"$();bidsize:"i"$();ask:"f"$();asksize:"i"$();cond:`$();mmid:();bidexch:`$();askexch:`$();sequence:"j"$();bbo:"c"$();qbbo:"c"$();corr:"c"$();cqs:"c"$();rpi:"c"$();shortsale:"c"$();cqsind:"c"$();utpind:"c"$();parttime:"p"$())


/-reset temporary db
reset:{
  .lg.o[`quotemerger;"clearing temporary db"];
  merged::([date:26#x;split:`$'.Q.A]status:26#0b);
  quotedir set empty;
  /quotedir set .Q.en[pardir;empty];
  .lg.o[`quotemerger;"temporary db cleared"];
 }

/-base merge function
merge:{
  .lg.o[`quotemerger;"Merging split ",string split];
  quotedir upsert get x[0];
  .lg.o[`quotemerger;string[split]," merged"];
  merged[(x[1];x[2])]:1b;
  return:1b
 }

/-quote merge function
mergesplit:{
  
  /-extracts split letter
  split:`$(reverse string x[`tablepath])[17];

  /-attempt to merge and keys result
  a:(0b;"Unsuccessful: already merged";.z.P);
  a:$[merged[(.z.d;split)][`status];a;@[{(merge x;"Success";.z.P)};(x[`tablepath];.z.d; split);{(0b;"Unsuccessful:",x;.z.P)}]];
  result:`mergestatus`mergemessage`mergeendtime!a;

  /-build return dictionary
  b:`=(merged?0b)[`split];
  returnkeys:`loadid`mergelocation`fullmergestatus;
  return:result,returnkeys!(x[`loadid];quotedir;b)
 }

/-function to run and log system commands 
syscmd:{
  .lg.o[`system;"running system command ",x]; 
  r:@[{(1b;system x)};x;{.lg.e[`system;"failed to run system command ",x];(0b;x)}];
  if[not first r; 'last r];
  last r
 };

/-moves merged quotes to todays date partition in hdb

movetohdb:{
  .lg.o[`quotemerger;"moving merged quote data to hdb"]
  /system" " sv ("mv"; 1_string[pardir];1_string[hdbdir]);
  syscmd[" " sv ("mv"; 1_string[pardir];1_string[hdbdir])];
  .lg.o[`quotemerger;"quote data moved to hdb"]
  .lg.o[`quotemerger;"resetting temporary database"]
  reset[.z.d]
  .lg.o[`quotemerger;"temporary database reset"]
  }


/-test input directory
x:`tablepath`tabletype`loadid!(`:/home/scooper/taqtest/tables/quoteA/2018.01.03/quote;`quote;1)
/-temporary, just to get empty table, will chance to "ticktime<.z.d"
empty:select from (get x[`tablepath]) where ticktime<2018.01.03