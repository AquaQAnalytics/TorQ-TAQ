.servers.CONNECTIONS:`taqloader`gateway
.servers.startup[]
.proc.loadf[getenv[`KDBCODE],"/processes/filealerter.q"]
h:first exec w from .servers.SERVERS where proctype in `gateway

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
    fileloading,:`loadid xkey enlist r
    };

// async message to invoke loader process when new nyse file is found
// this will invoke a loader slave to run loadtaqfile function in taqloader
runload:{
    l:startload[x;y]; 
    (neg h)(`.gw.asyncexecjpt;
        ({system"sleep 3"; x,(enlist `loadendtime)!enlist .z.p};
        `loadid`loadendtime!(l;.z.p));
        `taqloader;{x};`finishload;0Wn)
    };
