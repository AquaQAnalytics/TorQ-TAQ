hdbdir:hsym`$getenv[`KDBHDB],"/"
homedir:hsym `$getenv[`TORQHOME]
tempdbdir:hsym `$getenv[`TORQTAQTEMPDB]
mergedir:hsym `$getenv[`TORQTAQMERGED]

/-set global directories when needed
setdirs:{
  pardir::`$"/" sv (string tempdbdir;string x);
  quotedir::`$"/" sv (string pardir;"quote";"")
 }

/-reset temp hdb and update merged table
reset:{
  .lg.o[`quotemerger;"clearing temporary db"];
  `merged upsert ([date:26#x[`tabledate];split:`$'.Q.A]status:26#0b);
  empty:select from (get x[`tablepath]) where ticktime<x[`tabledate];
  quotedir set empty;
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
  
  setdirs[x[`tabledate]];

  /-extract split letter
  split:`$(reverse string x[`tablepath])[17];

  /-check if date has entries in merged table
  c:count a:exec distinct date from merged;
  if[c=a?x[`tabledate];reset[x]];

  /-attempt to merge and key result
  a:(0b;"Unsuccessful: already merged";.z.P);
  a:$[merged[(x[`tabledate];split)][`status];a;@[{(merge x;"Success";.z.P)};(x[`tablepath];x[`tabledate]; split);{(0b;"Unsuccessful:",x;.z.P)}]];
  result:`mergestatus`mergemessage`mergeendtime!a;

  /-save merged table for use in orchestrator process
  save mergedir;

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

/-move merged quotes to date partition in hdb
movetohdb:{
  setdirs x;
  .lg.o[`quotemerger;"moving merged quote data to hdb"]
/  system" " sv ("mv"; 1_string[pardir];1_string[hdbdir]);
  syscmd[" " sv ("mv"; 1_string[pardir];1_string[hdbdir])];
  .lg.o[`quotemerger;"quote data moved to hdb"]
  }

/-test input directory
x:`tablepath`tabletype`loadid`tabledate!(`:/home/scooper/taqtest/tables/quoteA/2018.01.03/quote;`quote;1;2018.01.03)
/-attempt to load merged table, create it if it doesnt exist
@[{get x};mergedir;{merged::([date:"d"$();split:"s"$()]status:"b"$())}]