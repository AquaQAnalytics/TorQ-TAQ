optionalparams:@[value;`optionalparams;()!()];
.servers.CONNECTIONS:enlist `gateway
.servers.startup[]
.proc.loadf[getenv[`KDBCODE],"/processes/filealerter.q"]
h:.servers.getserverbytype[`gateway;`w;`any]

// table to track progress of each file to load
fileloading:(
    [loadid:`int$()]
    filename:`symbol$();
    filetype:`symbol$();
    loadstarttime:`timestamp$();
    loadendtime:`timestamp$();
    mergestarttime:`timestamp$();
    mergeendtime:`timestamp$()
    );

// table of jobs in flight
filestatus:(
    []time:`timestamp$();
    id:`symbol$();                   // id is filename
    status:`symbol$()                // status is one of `waiting`loading`complete`error
    ) 

// updates fileloading table upon initiation of loader for each file
startload:{
    loadid+:1; 
    `fileloading upsert 1!enlist`loadid`filename`filetype`loadstarttime!(loadid;x;y;.z.p);
    loadid
    }; 

// update record that file has been loaded
finishload:{[q;r] 
    fileloading[loadid]:@[fileloading[loadid];`loadendtime;:;r[`loadendtime]];
    r[`loadid]:loadid;
    // if filetype is a quote invoke merger here
    if[r[`filetype]=`quote;
        fileloading[loadid]:@[fileloading[loadid];`mergestarttime;:;.z.P];
        (neg h)(`.gw.asyncexecjpt;
            (`mergesplit;r);
            `qmerger;{x};`finishmerge;0Wn);
      ];
    };

// async message to invoke loader process when new nyse file is found
// this will invoke a loader slave to run loadtaqfile function in taqloader
runload:{[path;file]
    filepath:hsym`$path,file;
    // define filetype based on name of incoming file from filealerter
    filetype: $[
    ("TRADE" inter file)~"TRADE";`trade;
    ("SPLITS" inter file)~"SPLITS";`quote;
    ("NBBO" inter file)~"NBBO";`nbbo;
    [.lg.e[`fifoloader;errmsg:(string file)," is an unknown or unsupported file type"];'errmsg]];
    
    // update monitoring table
    startload[filepath;filetype];  // defines loadid globally 

    // async call to gw to invoke loader process to load file
    .lg.o[`runload;"Initiating loader process"];
    (neg h)(`.gw.asyncexecjpt; 
        (`loadtaqfile;filetype;hsym `$filepath;optionalparams);
        `taqloader;{x};`finishload;0Wn)
    };
