//dictionary to keep track of merged split files
mergedsplits:(`$'.Q.A)!26#0b

//keys of the returned dictionary from merge function (move into function)
returnkeys:`loadid`mergestatus`mergemessage`mergelocation`mergeendtime`fullmergestatus

//store paths of temporary directory
homepath:`$raze":",system["pwd"],"/"
tempdbpath:`$(string homepath),"tempdb/"

//initialise empty temporary hdb
tempdb:([]date:"d"$();sym:`$();ticktime:"p"$();exch:"s"$();bid:"f"$();bidsize:"i"$();ask:"f"$();asksize:"i"$();cond:`$();mmid:();bidexch:`$();askexch:`$();sequence:"j"$();bbo:"c"$();qbbo:"c"$();corr:"c"$();cqs:"c"$();rpi:"c"$();shortsale:"c"$();cqsind:"c"$();utpind:"c"$();parttime:"p"$())
tempdbpath set .Q.en[homepath;tempdb]

//test input directory
x:`tablepath`tabletype`quote!(`:/home/scooper/taqtest/tables/quoteA;`quote;1)

//quote merge function
mergesplits:{
  system"l ",1_string x[`tablepath];
  loadid:x[`loadid];
  tempdbpath upsert .Q.en[homepath;select from quote]
  a:.z.P;
  mergedsplits[`$last string x[`tablepath]]:1b;
  b:`=mergedsplits?0b;
  return:returnkeys!(1;1b;"successfully merged";`tbi;a;b);
  neg[.z.w] return}

movetohdb:{neg[.z.w] 4}

