hdbdir:@[value;`hdbdir;.taq.hdbdir]
symdir:@[value;`symdir;.taq.symdir]
tempdb:@[value;`tempdb;.taq.tempdb]
filedrop:@[value;`filedrop;`:filedrop]
optionalparams:@[value;`optionalparams;()!()]

timeconverter:{
    "n"$sum 3600000000000 60000000000 1000000000 1*deltas[d*x div/: d]div d:10000000000000 100000000000 1000000000 1
  };

// function to load all taq files from nyse
loadtaqfile:{[taqloaderparams;optionalparams]
    // boolean to determine if load function should be executed or not
    doload:1b;
    // empty error message if the load is successful, otherwise error message will be printed to monitoring table as a string
    errmsg:"success";
    // initial definition of the dictionary to return upon completion or exit
    returndict:(!) . flip (
        (`tablepath;`);
        (`tabletype;taqloaderparams[`filetype]);
        (`loadid;taqloaderparams[`loadid]);
        (`tabledate;@[{"D"$-8#-3_string x};taqloaderparams`filetoload;0Nd]));
    // Check if date was successfully extracted, if not exit with error
    if[0Nd~returndict`tabledate;
        .lg.e[`loadtaqfile;errmsg:("Could not extract date in "),string taqloaderparams`filetoload];
        :buildreturndict[returndict;0h;errmsg]];
    // Check if file exists in filedrop directory, otherwise exit with error
    $[taqloaderparams[`filetoload] in key[.taq.filedrop];
        .lg.o[`loadtaqfile;raze "File successfully found in ",getenv[`TORQTAQFILEDROP]];
        doload:0b];
    if[not doload;.lg.e[`loadtaqfile;
        errmsg:"Could not find: ",.os.pth taqloaderparams`filepath];
        :buildreturndict[returndict;0h;errmsg]];
    // if file name is correct and exists in filedrop directory, execute the load  
    if[doload;
        params:buildparams[taqloaderparams`filetype;returndict;taqloaderparams`filetoload];
        :executeload[params;taqloaderparams`filepath;taqloaderparams`filetoload;returndict;taqloaderparams`filetype;errmsg]];
  };

// function for constructing return dictionary in loadtaqfile
buildreturndict:{[d;s;e] 
    d,`loadendtime`loadstatus`loadmessage!(.proc.cp[];s;e)
  };

// function for building parameters used in loadtaqfile based on file type
buildparams:{[ft;rd;ftl]
    p:$[
        ft~`trade;fileparams[`trade],optionalparams;
        ft~`quote;fileparams[`quote],optionalparams;
        ft~`nbbo;fileparams[`nbbo],optionalparams;
        [.lg.e[`fifoloader;errmsg:(string ft)," is an unknown or unsupported file type"];
        :buildreturndict[rd;0h;errmsg]]];
    p[`dbdir]:$[
        ft~`trade;`$(string p[`tempdb]),"/final";
        ft~`quote;`$(string p[`tempdb]),"/",(string ft),last -12_string ftl;
        `$(string p[`tempdb]),"/final"];p
  };

// function to execute the load of the taq file in loadtaqfile
executeload:{[p;fp;ftl;d;ft;em]
    fifo:"/tmp/fifo",string .z.i;
    p[`date]:d`tabledate;
    // remove fifo if it exists then make new one
    syscmd["rm -f ",fifo," && mkfifo ",fifo];
    syscmd["gunzip -c ",(.os.pth fp)," > ",fifo," &"];
    .lg.o[`fifoloader;"Loading ",(string ftl)];
    // execute load, trap error if load is unsuccessful and assign the error message for monitoring table
    loadmsg:.[{.Q.fpn[x;y;z]};(.loader.loaddata[p,(enlist`filename)!enlist `$-3_string ftl];hsym `$fifo;p`chunksize);
        {[e] .lg.e[`loadtaqfile;msg:"Failed to complete load with error: ",e];(0b;msg)}];
    if[0b~first loadmsg;:buildreturndict[d;0h;last loadmsg]];
    .lg.o[`fifoloader;(string ftl)," has successfully been loaded"];
    syscmd["rm -f ",fifo];
    // assign value to table path only if table is successfully loaded here
    d[`tablepath]:hsym`$(string p[`dbdir]),"/",(string d`tabledate),"/",(string ft);
    buildreturndict[d;1h;em]
  };

// build taq load parameters
maketaqparams[]
