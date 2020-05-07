hdbdir:@[value;`hdbdir;`:hdbdir]
symdir:@[value;`symdir;`:symdir]
tempdb:@[value;`tempdb;`:tempdb]
optionalparams:@[value;`optionalparams;()!()] 
timeconverter:{"n"$sum 3600000000000 60000000000 1000000000 1*deltas[d*x div/: d]div d:10000000000000 100000000000 1000000000 1}
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
        (`tabledate;date:@[{"D"$-8#-3_string x};filetoload;0Nd]));
    if[0Nd~date;
        .lg.e[`loadtaqfile;errmsg:("Could not extract date in "),string filetoload];
        :buildreturndict[returndict;0h;errmsg]];
    $[filetoload in key[hsym`$getenv[`TORQTAQFILEDROP]];
        .lg.o[`loadtaqfile;raze "File successfully found in ", getenv[`TORQTAQFILEDROP]];
        doload:0b];
    if[not doload;.lg.e[`loadtaqfile;
        errmsg:"Could not find: ", .os.pth filepath];
        :buildreturndict[returndict;0h;errmsg]];  
    if[doload;
        // define params based on filetype
        params:$[
            filetype=`trade;tradeparams,optionalparams;
            filetype=`quote;quoteparams,optionalparams;
            filetype=`nbbo;nbboparams,optionalparams;
            [.lg.e[`fifoloader;errmsg:(string filetype)," is an unknown or unsupported file type"];
            :buildreturndict[returndict;0h;errmsg]]];
        // if quote then partition by letter in the temp hdb
        params[`dbdir]:$[
            filetype=`trade;`$(string params[`tempdb]),"/final/";
            filetype=`quote;`$(string params[`tempdb]),"/",(string filetype),last -12_string filetoload;
            `$(string params[`tempdb]),"/final/"];
        // make fifo with PID attached
        fifo:"/tmp/fifo",string .z.i;
        params[`date]:date;
        // remove fifo if it exists then make new one
        syscmd["rm -f ",fifo," && mkfifo ",fifo];
        syscmd["gunzip -c ",(.os.pth filepath)," > ",fifo," &"];
        .lg.o[`fifoloader;"Loading ",(string filetoload)];
        loadmsg:.[{.Q.fpn[x;y;z]};(.loader.loaddata[params,(enlist`filename)!enlist `$-3_string filetoload];hsym `$fifo;params`chunksize);
            {[e] .lg.e[`loadtaqfile;msg:"Failed to complete load with error:",e];(0b;msg)}];
        if[0b~first loadmsg;:buildreturndict[returndict;0h;last loadmsg]];
        .lg.o[`fifoloader;(string filetoload)," has successfully been loaded"];
        syscmd["rm ",fifo];
        returndict[`tablepath]:hsym`$(string params[`dbdir]),"/",(string date),"/",(string filetype);
        buildreturndict[returndict;1h;errmsg]
      ];
 };

 buildreturndict:{[d;s;e] d,`loadendtime`loadstatus`message!(.proc.cp[];s;e)};