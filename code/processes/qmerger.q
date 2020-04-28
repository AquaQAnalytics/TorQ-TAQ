hdbdir:hsym`$getenv[`KDBHDB],"/"
homedir:hsym `$getenv[`TORQHOME]
tempdbdir:hsym `$getenv[`TORQTAQTEMPDB]
mergedir:hsym `$getenv[`TORQTAQMERGED]

/-reset temp hdb and update merged table
reset:{
  .lg.o[`quotemerger;"clearing temporary db"];
  `merged upsert ([date:26#x[`tabledate];split:`$'.Q.A]status:26#0b);
  empty:select from (get x[`tablepath]) where ticktime<x[`tabledate];
  y set empty;
  .lg.o[`quotemerger;"temporary db cleared"];
 }

/-base merge function
merge:{
  .lg.o[`quotemerger;"Merging split ",string x[2]];
  x[3] upsert get x[0];
  .lg.o[`quotemerger;string[x[2]]," merged"];
  merged[(x[1];x[2])]:1b;
  return:1b
 }

/-quote merge function
mergesplit:{
  
  pardir:`$"/" sv (string tempdbdir;string x[`tabledate]);
  quotedir:`$"/" sv (string pardir;"quote";"");

  /-extract split letter
  split:`$(reverse string x[`tablepath])[17];

  /-check if date has entries in merged table
  c:count a:exec distinct date from merged;
  if[c=a?x[`tabledate];reset[x;quotedir]];

  /-attempt to merge and key result
  a:$[merged[(x[`tabledate];split)][`status];
    (0b;"Unsuccessful: already merged";.z.P);
    @[{(merge x;"Success";.z.P)};
      (x[`tablepath];x[`tabledate];split;quotedir);
      {(0b;"Unsuccessful:",x;.z.P)}
     ]
    ];
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
  pardir:`$"/" sv (string tempdbdir;string x);
  quotedir:`$"/" sv (string pardir;"quote";"");
  .lg.o[`quotemerger;"moving merged quote data to hdb"]
  syscmd[" " sv ("mv"; 1_string[pardir];1_string[hdbdir])];
  .lg.o[`quotemerger;"quote data moved to hdb"]
  }

/-attempt to load merged table, create it if it doesnt exist
merged:@[{get x};mergedir;{([date:"d"$();split:"s"$()]status:"b"$())}]