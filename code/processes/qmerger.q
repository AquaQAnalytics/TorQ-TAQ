hdbdir:@[value;`hdbdir;`:hdb]
tempdbdir:@[value;`tempdbdir;()!()]
mergedir:@[value;`mergedir;`:mergedir]

/-reset temp hdb and update merged table
reset:{
  .lg.o[`quotemerger;"creating date partition ",string x[`tabledate]];
  `merged upsert ([date:26#x[`tabledate];split:`$'.Q.A]status:26#0b);
  empty:select from (get x[`tablepath]) where ticktime<x[`tabledate]; //replace with something not dependent on data 
  y set empty;
  .lg.o[`quotemerger;"date partition created"];
 }

/-base merge function
merge:{
  .lg.o[`quotemerger;"Merging split ",string x[2]];
  x[3] upsert @[get;x[0];{[e] [.lg.e[`merge;errmsg:"Failed merge:",e];'splitnonexistant]}];
  .lg.o[`quotemerger;string[x[2]]," merged"];
  merged[(x[1];x[2])]:1b;
  return:1b
 }

/-quote merge function
mergesplit:{
  
  pardir:` sv tempdbdir,`final, `$string x[`tabledate];
  quotedir:` sv pardir,`quote,`;

  /-extract split letter, path of form `:/path/to/quoteA/date/table 
  split:`$first vs["/";reverse string x[`tablepath]][2];

  /-check if date has entries in merged table
  c:count a:exec distinct date from merged;
  if[c=a?x[`tabledate];reset[x;quotedir]];

  /-attempt to merge and key result
  .lg.o[`quotemerger;"Attempting to merge split ",string split];

  $[merged[(x[`tabledate];split)][`status];.lg.o[`quotemerger;"Unsuccessful: already merged"];];
  
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

  syscmd["rm -r ",1_"/" sv -2_vs["/";string x[`tablepath]]];

  /-build return dictionary
  b:`=(merged?0b)[`split];
  returnkeys:`loadid`mergelocation`fullmergestatus;
  return:result,returnkeys!(x[`loadid];quotedir;b)
 }

/-move merged quotes to date partition in hdb
movetohdb:{
  pardir:` sv tempdbdir,`final, `$string x[`tabledate];
  .lg.o[`quotemerger;"moving merged quote data to hdb"]
  syscmd[" " sv ("mv"; 1_string[pardir];1_string[hdbdir])];
  .lg.o[`quotemerger;"quote data moved to hdb"];
  .lg.o[`quotemerger;"clearing ",string x, " from temporary database"];
  syscmd["rm -r ",string pardir];
  .lg.0[`quotemerger;"temporary db cleared"];
  }

/-attempt to load merged table, create it if it doesnt exist
merged:@[{get x};mergedir;{([date:"d"$();split:"s"$()]status:"b"$())}]
