hdbdir:hsym`$getenv[`KDBHDB],"/"
homedir:hsym `$getenv[`TORQHOME]
tempdbdir:hsym `$getenv[`TORQTAQTEMPDB]
quotedir:`$(string tempdbdir),"quote/"

//initialise empty temporary hdb
empty:([]date:"d"$();sym:`$();ticktime:"p"$();exch:"s"$();bid:"f"$();bidsize:"i"$();ask:"f"$();asksize:"i"$();cond:`$();mmid:();bidexch:`$();askexch:`$();sequence:"j"$();bbo:"c"$();qbbo:"c"$();corr:"c"$();cqs:"c"$();rpi:"c"$();shortsale:"c"$();cqsind:"c"$();utpind:"c"$();parttime:"p"$())

//resets temporary db
reset:{
  merged::(`$'.Q.A)!26#0b;
  quotedir set .Q.en[tempdbdir;empty]
 }

//base merge function
merge:{
  .lg.o[`quotemerger;"Merging split ",string split];
  quotedir upsert .Q.en[tempdbdir;x];
  .lg.o[`quotemerger;string[split]," merged"];
  merged[split]:1b;
  return:1b
 }

//quote merge function
mergesplit:{
  //load quote table from file path
  system"l ",1_string x[`tablepath];
  split::`$last string x[`tablepath];

  //un-enumerate quote table
  symcols:exec c from meta quote where t="s";
  tab:@[select from quote;symcols;value];

  //attempt to merge and keys result
  a:(0b;"Unsuccessful: already merged";.z.P);
  a:$[0b=merged[split];@[{(merge x;"Success";.z.P)};tab;{(0b;"Unsuccessful:",x;.z.P)}];a];
  result:`mergestatus`mergemessage`mergeendtime!a;
  merged[split]:1b;

  //build return dictionary
  b:`=merged?0b;
  returnkeys:`loadid`mergelocation`fullmergestatus;
  return:result,returnkeys!(x[`loadid];tempdbdir;b)
 }


//moves merged quotes to todays date partition in hdb
/
movetohdb:{
  system"l ",1_string tempdbdir;
  symcols:exec c from meta quote where t="s";
  quote:@[select from quote;symcols;value];
  .Q.dpft[hdbdir;.z.d;`sym;`quote];
  reset[]
 }
\

//test input directory
x:`tablepath`tabletype`loadid!(`:/home/scooper/taqtest/tables/quoteA;`quote;1)
