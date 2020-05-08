hdbdir:@[value;`hdbdir;`:hdbdir]
symdir:@[value;`symdir;`:symdir]
tempdb:@[value;`tempdb;`:tempdb]
optionalparams:@[value;`optionalparams;()!()]
defaults:`chunksize`partitioncol`partitiontype`compression`gc!(`int$100*2 xexp 20;`ticktime;`date;();0b)

// set the schema for each table
tradeparams:defaults,(!) . flip (
    (`headers;`ticktime`exch`sym`cond`size`price`stop`corr`sequence`tradeid`cts`trf`parttime);
    (`types;"JSSSIFBIJICCJ");
    (`tablename;`trade);
    (`separator;enlist"|");
    (`dbdir;hdbdir);             // this parameter is defined in the top level taqloader script
    (`symdir;symdir);            // where we enumerate against
    (`tempdb;tempdb);
    (`dataprocessfunc;{[params;data] `sym`ticktime`exch`cond`size`price`stop`corr`sequence`cts`trf xcols delete from
    (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data) where null ticktime});
    (`date;.z.d)
        );

quoteparams:defaults,(!) . flip (
    (`headers;`ticktime`exch`sym`bid`bidsize`ask`asksize`cond`sequence`bbo`qbbo`cqs`rpi`shortsale`utpind`parttime);
    (`types;"JSSFIFISJCC  CCCC  J");
    (`tablename;`quote);
    (`separator;enlist"|");
    (`dbdir;hdbdir);               // this parameter is defined in the top level taqloader script
    (`symdir;symdir);              // where we enumerate against
    (`tempdb;tempdb);
    (`dataprocessfunc;{[params;data]
        `sym`ticktime`exch`bid`bidsize`ask`asksize`cond`mmid`bidexch`askexch`sequence`bbo`qbbo`corr`cqs`rpi`shortsale`cqsind`utpind`parttime xcols
            update mmid:(count ticktime)#enlist "",bidexch:`,askexch:`,corr:" ",cqsind:" " from
              delete from
              (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data)
              where null ticktime});
    (`date;.z.d)
        );

nbboparams:defaults,(!) . flip (
    (`headers;`ticktime`exch`sym`bid`bidsize`ask`asksize`cond`sequence`bbo`qbbo`cqs`qcond`bbex`bbprice`bbsize`bbmmid`baex`baprice`basize`bammid`luldind`nbboind`parttime);
    (`types;"JSSFIFISJCC  CCCFI*CFI*CC J");
         (`tablename;`nbbo);
         (`separator;enlist"|");
         (`dbdir;hdbdir);             // this parameter is defined in the top level taqloader script
         (`symdir;symdir);            // where we enumerate against
         (`tempdb;tempdb);
         (`dataprocessfunc;{[params;data] 
	`sym`ticktime`exch`bid`bidsize`ask`asksize`cond`mmid`bidexch`askexch`sequence`bbo`qbbo`corr`cqs`qcond`bbex`bbprice`bbsize`bbmmid`bbmmloc`bbmmdeskloc`baex`baprice`basize`bammid`bammloc`bammdeskloc`luldind`nbboind`parttime xcols 
	// add in blank fields which don't exist any more 
 	update mmid:(count ticktime)#enlist "",bidexch:`,askexch:`,corr:" ",bbmmloc:`,bbmmdeskloc:" ",bammloc:`,bammdeskloc:" " from 
 	   delete from 
	   (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data) 
	  where null ticktime});
         (`date;.z.d)
        );

// function to load all taq files from nyse
loadtaqfile:{[filetype;filetoload;filepath;loadid;optionalparams]
    doload:1b;
    errmsg:"";
    returndict:(!) . flip (
        (`tablepath;`);
        (`tabletype;filetype);
        (`loadid;loadid);
        (`tabledate;@[{"D"$-8#-3_string x};filetoload;0Nd]));
    if[0Nd~returndict`tabledate;
        .lg.e[`loadtaqfile;errmsg:("Could not extract date in "),string filetoload];
        :buildreturndict[returndict;0h;errmsg]];
    $[filetoload in key[hsym`$getenv[`TORQTAQFILEDROP]];
        .lg.o[`loadtaqfile;raze "File successfully found in ",getenv[`TORQTAQFILEDROP]];
        doload:0b];
    if[not doload;.lg.e[`loadtaqfile;
        errmsg:"Could not find: ",.os.pth filepath];
        :buildreturndict[returndict;0h;errmsg]];  
    if[doload;
        params:buildparams[filetype;returndict;filetoload];
        :executeload[params;filepath;filetoload;returndict;filetype;errmsg]];
  };

timeconverter:{
    "n"$sum 3600000000000 60000000000 1000000000 1*deltas[d*x div/: d]div d:10000000000000 100000000000 1000000000 1
  };

buildreturndict:{[d;s;e] 
    d,`loadendtime`loadstatus`message!(.proc.cp[];s;e)
  };

buildparams:{[ft;rd;ftl]
    p:$[
        ft~`trade;tradeparams,optionalparams;
        ft~`quote;quoteparams,optionalparams;
        ft~`nbbo;nbboparams,optionalparams;
        [.lg.e[`fifoloader;errmsg:(string ft)," is an unknown or unsupported file type"];
        :buildreturndict[rd;0h;errmsg]]];
    p[`dbdir]:$[
        ft~`trade;`$(string p[`tempdb]),"/final/";
        ft~`quote;`$(string p[`tempdb]),"/",(string ft),last -12_string ftl;
        `$(string params[`tempdb]),"/final/"];p
  };

executeload:{[p;fp;ftl;d;ft;em]
    fifo:"/tmp/fifo",string .z.i;
    p[`date]:d`tabledate;
    // remove fifo if it exists then make new one
    syscmd["rm -f ",fifo," && mkfifo ",fifo];
    syscmd["gunzip -c ",(.os.pth fp)," > ",fifo," &"];
    .lg.o[`fifoloader;"Loading ",(string ftl)];
    loadmsg:.[{.Q.fpn[x;y;z]};(.loader.loaddata[p,(enlist`filename)!enlist `$-3_string ftl];hsym `$fifo;p`chunksize);
        {[e] .lg.e[`loadtaqfile;msg:"Failed to complete load with error:",e];(0b;msg)}];
    if[0b~first loadmsg;:buildreturndict[d;0h;last loadmsg]];
    .lg.o[`fifoloader;(string ftl)," has successfully been loaded"];
    syscmd["rm ",fifo];
    d[`tablepath]:hsym`$(string p[`dbdir]),"/",(string d`tabledate),"/",(string ft);
    buildreturndict[d;1h;em]
  };