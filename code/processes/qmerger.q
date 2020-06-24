\d .taq

hdbdir:@[value;`hdbdir;`:hdb]
symdir:@[value;`symdir;`:symdir]
tempdb:@[value;`tempdb;`:tempdb]
mergedir:@[value;`mergedir;`:mergedir]

\d .

// reset temp hdb and update merged table
reset:{
  .lg.o[`quotemerger;"creating date partition ",string x[`tabledate]];
  `merged upsert ([date:26#x[`tabledate];split:`$'.Q.A]status:26#0b);
  empty:select from (get x[`tablepath]) where ticktime<x[`tabledate];  
  y set empty;
  .lg.o[`quotemerger;"date partition created"];
  };

// base merge function
merge:{
  .lg.o[`quotemerger;"Merging split ",string x[2]];
  x[3] upsert @[get;x[0];{[e] [.lg.e[`merge;errmsg:"Failed merge:",e];'splitnonexistant]}];
  .lg.o[`quotemerger;string[x[2]]," merged"];
  merged[(x[1];x[2])]:1b;
  return:1b
  };

// quote merge function
mergesplit:{
  pardir:` sv .taq.tempdb,`final, `$string x[`tabledate];
  quotedir:` sv pardir,`quote,`;
  // extract split letter, path of form `:/path/to/quoteA/date/table 
  split:`$first vs["/";reverse string x[`tablepath]][2];
  // check if date has entries in merged table
  c:count a:exec distinct date from merged;
  if[c=a?x[`tabledate];reset[x;quotedir]];
  // attempt to merge and key result
  .lg.o[`quotemerger;"Attempting to merge split ",string split];
  $[merged[(x[`tabledate];split)][`status];.lg.o[`quotemerger;"unsuccessful: already merged"];];
  a:$[merged[(x[`tabledate];split)][`status];
    (0b;"unsuccessful: already merged";.z.P);
    @[{(merge x;"success";.z.P)};
      (x[`tablepath];x[`tabledate];split;quotedir);
      {(0b;"unsuccessful:",x;.z.P)}
     ]
    ];
  result:`mergestatus`mergemessage`mergeendtime!a;
  // save merged table for use in orchestrator process
  save .taq.mergedir;
  syscmd["rm -r ",1_"/" sv -2_vs["/";string x[`tablepath]]];
  // build return dictionary
  b:`=(merged?0b)[`split];
  returnkeys:`loadid`mergelocation`fullmergestatus;
  result,returnkeys!(x[`loadid];quotedir;b)
  };

// move merged quotes to date partition in hdb
movepartohdb:{[date;loadfiles]
  makeemptyschema[loadfiles];
  pardir:` sv .taq.tempdb,`final, `$string date;
  .lg.o[`quotemerger;"moving merged quote data to hdb"]
  syscmd[" " sv ("mv";.os.pth pardir;.os.pth .taq.hdbdir)];
  .lg.o[`quotemerger;"quote data moved to hdb"];
  :1b
  };

manmovetohdb:{[date;filetype]
  ft:(),filetype;
  pd:` sv .taq.tempdb,`final, `$string date;
  paths:.Q.dd[pd]each ft,'`;
  if[not (`$string[date]) in key[.taq.hdbdir];syscmd["mkdir ",(.os.pth .taq.hdbdir),"/",string[date]]];
  .lg.o[`manmovetohdb;"Manually moving data in ",(.os.pth pd)," to hdb"];
  cmd:({"mv ",(.os.pth x)," ",(.os.pth y),"/",string[z],"/"}[;.taq.hdbdir;date]each paths),'string[ft],'"/";
  syscmd'[cmd];
  .lg.o[`manmovetohdb;"successfully moved data to hdb"];
  };

// function which makes empty schema for tables that are not selected for download
makeemptyschema:{[loadfiles;date]
  pardir:` sv .taq.tempdb,`final, `$string date;
  ftypes:`trade`quote`nbbo;
  emptyfiles:ftypes except loadfiles;
  emptytaqschema[];                                             // located in code/common/taq.q
  paths:.Q.dd[pardir]each emptyfiles,'`;
  paths set' .Q.en[.taq.symdir;]each emptyschemas[emptyfiles];  // save empty schemas in tempdb, enumerates to same place 
  };


// attempt to load merged table, create it if it doesnt exist
merged:@[{get x};.taq.mergedir;{([date:"d"$();split:"s"$()]status:"b"$())}]