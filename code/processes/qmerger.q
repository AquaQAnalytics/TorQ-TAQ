hdbdir:hsym`$getenv[`KDBHDB],"/"
homedir:hsym `$getenv[`TORQHOME]
tempdbdir:hsym `$getenv[`TORQTAQTEMPDB]
pardir:`$"/" sv (string tempdbdir;string 2018.01.03;"")
quotedir:`$(string pardir),"quote/"

/-initialise empty temporary hdb
//empty:([]sym:`$();ticktime:"p"$();exch:"s"$();bid:"f"$();bidsize:"i"$();ask:"f"$();asksize:"i"$();cond:`$();mmid:();bidexch:`$();askexch:`$();sequence:"j"$();bbo:"c"$();qbbo:"c"$();corr:"c"$();cqs:"c"$();rpi:"c"$();shortsale:"c"$();cqsind:"c"$();utpind:"c"$();parttime:"p"$())


/-reset temporary db
reset:{
  /.lg.o[`quotemerger;"clearing temporary db"];
  merged::([date:26#.z.d;split:`$'.Q.A]status:26#0b);
  quotedir set empty;
  /.lg.o[`quotemerger;"temporary db cleared"];
 }

/-base merge function
merge:{
  /.lg.o[`quotemerger;"Merging split ",string split];
  quotedir upsert get x;
  /.lg.o[`quotemerger;string[split]," merged"];
  merged[(.z.d;split)]:1b;
  return:1b
 }

/-quote merge function
mergesplit:{

  split::`$last string x[`tablepath];

  /-attempt to merge and keys result
  a:(0b;"Unsuccessful: already merged";.z.P);
  a:$[merged[(.z.d;split)][`status]=0b;@[{(merge x;"Success";.z.P)};x[`tablepath];{(0b;"Unsuccessful:",x;.z.P)}];a];
  result:`mergestatus`mergemessage`mergeendtime!a;
  merged[(.z.d;split)]:1b;

  /-build return dictionary
  b:`=(merged?0b)[`split];
  returnkeys:`loadid`mergelocation`fullmergestatus;
  return:result,returnkeys!(x[`loadid];tempdbdir;b)
 }


/-moves merged quotes to todays date partition in hdb

movetohdb:{
  system"l ",1_string tempdbdir;
  symcols:exec c from meta quote where t="s";
  quote2:@[select from quote;symcols;value];
  .Q.dpft[hdbdir;.z.d;`sym;`quote2];
  reset[]
  }


/-test input directory
x:`tablepath`tabletype`loadid!(`:/home/scooper/taqtest/tables/quoteA/2018.01.03/quote;`quote;1)
/-temporary, just to get empty table
empty:select from (get x[`tablepath]) where ticktime<2018.01.03