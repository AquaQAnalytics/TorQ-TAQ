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
    message:())
    );

// updates fileloading table upon initiation of loader for each file
startload:{
    loadid+:1; 
    `fileloading upsert 1!enlist`loadid`filename`filetype`loadstarttime!(loadid;x;y;.z.p);
    loadid
    }; 

// update record that file has been loaded
finishload:{[q;r]
    // if taqloader isn't available, error is returned and r is a string 
    if[10=type r;
        fileloading[loadid]:@[fileloading[loadid];`loadendtime;:;.proc.cp[]];
        fileloading[loadid]:@[fileloading[loadid];`loadstatus;:;0h];
        .lg.o[`finishload;r]];
    // updated monitoring stats
    fileloading[loadid]:@[fileloading[loadid];`loadendtime;:;r[`loadendtime]];
    fileloading[loadid]:@[fileloading[loadid];`loadstatus;:;r[`loadstatus]];
    fileloading[loadid]:@[fileloading[loadid];`message;:;r[`message]];
    // if filetype is a quote invoke merger here
    if[r[`tabletype]=`quote;
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
