//dictionary to keep track of merged split files
mergedsplits:(`$'.Q.A)!26#0b

//keys of the returned dictionary from merge function (move into function)
returnkeys:`loadid`mergestatus`mergemessage`mergelocation`mergeendtime`fullmergestatus

//store paths of temporary directory
tempdbpath:`$raze":",system["pwd"],"/tempdb/"
quotepath:`$(string tempdbpath),"quote/"

//initialise empty temporary hdb
empty:([]date:"d"$();sym:`$();ticktime:"p"$();exch:"s"$();bid:"f"$();bidsize:"i"$();ask:"f"$();asksize:"i"$();cond:`$();mmid:();bidexch:`$();askexch:`$();sequence:"j"$();bbo:"c"$();qbbo:"c"$();corr:"c"$();cqs:"c"$();rpi:"c"$();shortsale:"c"$();cqsind:"c"$();utpind:"c"$();parttime:"p"$())
quotepath set .Q.en[tempdbpath;empty]

//test input directory
x:`tablepath`tabletype`quote!(`:/home/scooper/taqtest/tables/quoteA;`quote;1)



//quote merge function
mergesplits:{
  system"l ",1_string x[`tablepath];                                    //loads quote tabke to be merged
  symcols:exec c from meta quote where t="s";                           //execs enumerated columns
  quote2:@[select from quote;symcols;value];                            //extracts un-enumerated table
  quotepath upsert .Q.en[tempdbpath;quote2];                            //upserts to temporary db
  a:.z.P;                                                               //saves completion time
  mergedsplits[`$last string x[`tablepath]]:1b;                         //updates dic of successfully merged split files
  b:`=mergedsplits?0b;                                                  //checks if all merges are done
  return:returnkeys!(x[`loadid];1b;"successfully merged";`tbi;a;b);     //forms return dictionary
  neg[.z.w] return}

movetohdb:{}
