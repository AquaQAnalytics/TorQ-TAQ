optionalparams:@[value;`optionalparams;()!()]
.servers.CONNECTIONS:enlist `gateway
.servers.startup[]
.proc.loadf[getenv[`KDBCODE],"/processes/filealerter.q"]

// table to track progress of each file to load
fileloading:(
    [loadid:`int$()]
    filename:`symbol$();
    filetype:`symbol$();
    loadstarttime:`timestamp$();
    loadendtime:`timestamp$();
    mergestarttime:`timestamp$();
    mergeendtime:`timestamp$();
    loadstatus:`short$();
    message:()
    );

// updates fileloading table upon initiation of loader for each file
startload:{
    loadid+:1; 
    `fileloading upsert 1!enlist`loadid`filename`filetype`loadstarttime!(loadid;x;y;.z.p);
    loadid
    }; 

// update record that file has been loaded
finishload:{[q;r]
    // if taqloader isn't available, error is returned and r is a string with connection error 
    if[10=type r;
        fileloading[loadid]:@[fileloading[loadid];`loadendtime`loadstatus`message;:;(.proc.cp[];0h;r)];
        .lg.o[`finishload;r];:()];
    // updated monitoring stats
    fileloading[loadid]:@[fileloading[loadid];`loadendtime`loadstatus`message;:;(r[`loadendtime];r[`loadstatus];r[`message])];
    // if filetype is a quote invoke merger here
    if[(r[`tabletype]~`quote) and ""~r[`message];
        fileloading[loadid]:@[fileloading[loadid];`mergestarttime;:;.proc.cp[]];
        h:.servers.getserverbytype[`gateway;`w;`any];
        (neg h)(`.gw.asyncexecjpt;
            (`mergesplit;4#r);
            `qmerger;{x};`finishmerge;0Wn);
      ];
    };

finishmerge:{[q;r]
    fileloading[loadid]:@[fileloading[loadid];`mergeendtime;:;.proc.cp[]];
  };

// async message to invoke loader process when new nyse file is found
// this will invoke a loader slave to run loadtaqfile function in taqloader
runload:{[path;file]
    // check if file has already been loaded
    if[1h in exec loadstatus from fileloading where filename=`$file;
        .lg.o[`runload;"The following file has already been successfully loaded: ", file];
        .lg.o[`runload;"Exiting load function"]:();];
    filepath:hsym`$path,file;
    // define filetype based on name of incoming file from filealerter
    filetype: $[
    file like "*TRADE*";`trade;
    file like "*SPLITS*";`quote;
    file like "*NBBO*";`nbbo;
    [.lg.e[`fifoloader;errmsg:(string file)," is an unknown or unsupported file type"];'errmsg]];
    // update monitoring table
    startload[`$file;filetype];  // defines loadid globally 
    // open handle to gateway
    h:.servers.getserverbytype[`gateway;`w;`any];
    // async call to gw to invoke loader process to load file
    .lg.o[`runload;"Initiating loader process"];
    (neg h)(`.gw.asyncexecjpt; 
        (`loadtaqfile;filetype;`$file;filepath;loadid;optionalparams);
        `taqloader;{x};`finishload;0Wn);
    };