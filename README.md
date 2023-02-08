# TorQ-TAQ

The TorQ-TAQ Loader architecture is an extension to TorQ, which efficiently loads NYSE TAQ files using the streaming decompress algorithm with .Q.fpn  

# Quick Installisation

To download TorQ TAQ, get latest installation script and download it to the directory where you want your codebase to live

````
wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ-TAQ/master/installlatest.sh
````

Then run the following line in the same working directory

`bash installlatest.sh`

Once this is complete, the necessary TorQ packages will be installed 
````
.
├── datatemp
│   ├── filedrop
│   ├── logs
│   ├── tplogs
│   ├── wdb
│   └── wdbhdb
├── deploy
│   ├── bin
│   ├── data -> ~/datatemp
│   ├── TorQ
│   └── TorQApp
├── installlatest.sh
├── installtorqapp.sh
├── TorQ-4.3.0.tar.gz
└── TorQ-TAQ-1.0.0.tar.gz
````
# Running TorQ-TAQ
To start TorQ TAQ, run the following command within your terminal:

````
$ ./bin/torq.sh start all
15:36:23 | Starting discovery1...
15:36:23 | Starting gateway1...
15:36:23 | Starting orchestrator1...
15:36:23 | Starting taqloader1...
15:36:24 | Starting taqloader2...
15:36:24 | Starting qmerger1...

$ ./bin/torq.sh summary
TIME      |  PROCESS        |  STATUS  |  PID    |  PORT
15:36:56  |  discovery1     |  up      |  21434  |  10610
15:36:57  |  gateway1       |  up      |  21607  |  10611
15:36:57  |  orchestrator1  |  up      |  21978  |  10612
15:36:57  |  taqloader1     |  up      |  22097  |  10613
15:36:57  |  taqloader2     |  up      |  22209  |  10614
15:36:58  |  qmerger1       |  up      |  22320  |  10615
````

The user must download TAQ .gz files to a directory on disk called filedrop in the upper-level TorQ directory.  At this point, the orchestrator will recognise a new file exists in this filedrop directory and invoke a loader process. 

Three files are currently supported: trade, quote, and national best bid offer (nbbo).  These files have the form:

- `EQY_US_ALL_TRADE_YYYYMMDD.gz` *(Trades)* 
- `EQY_US_ALL_NBBO_YYYYMMDD.gz` *(National Best Bid Offer)* 
- `SPLITS_US_ALL_BBO_*_YYYYMMDD.gz` *(Best Bid Offer - 26 files per day)* 

Depending on if the file recognised is a trade, quote or nbbo file, the way the data is saved behaves differently. 

## Trade/NBBO ##
Trade/NBBO data is laoded to the temporary HDB - tempdb, located in `deploy/tempdb/final/YYYY.MM.DD/trade|nbbo/`

**_NOTE:_** tempdb and hdb directories are created once a TAQ .gz file is loaded in - the paths to these directories are defined within [default.q](appconfig/settings/default.q)

By default, when Trade/NBBO data is loaded to the temporary HDB, it lives in the `deploy/tempdb/final/YYYY.MM.DD/` directory until all data from this day has been loaded. 

## Quote ##

Quote data is loaded to `deploy/tempdb/quote*/YYYY.MM.DD/quote/`

It is important to note that for the quote files, there are 26 split files (A-Z) and so when quote data is loaded, it is saved in the tempdb directory but saved as a partition of the quote split file that is being loaded (quoteA, quoteB, quoteC etc.). 

When the quote split file has been loaded successfully, it is merged using the merger process.  This merger process merges the quote split file to the same location as the trade and/or nbbo data in deploy/tempdb/final/YYYY.MM.DD/quote.  The split files do not have to be loaded in alphabetical order; i.e., split file B can be loaded and merged before split file A.

When the trade, nbbo and all 26 quote split files have been successfully loaded and merged, the orchestrator then calls the merge process to call the function which moves all of the loaded and merged data to the final hdb in its relevant date partition.

## Support Functionality ##
### Saving to HDB ###

We have included a function called `manualmovetohdb` – This function can be called with arguments `[date;filetype]` in the orchestrator to manually move loaded data to the hdb. date is a date atom and filetype is a symbol or list of symbols (any of trade, quote, or nbbo). By default, data is only moved when all files have been successfully loaded and merged. However, this can be called to move the data at a different point in time.

### Changing Table Schema ###
As was already indicated, TorQ-TAQ currently supports trade, quote, and national best bid offer (nbbo) files from the NYSE website. Although [taq.q](code/common/taq.q) contains functionality for adjusting the schema of these tables. Users can modify the columnames and datatypes of these tables to meet their needs or to use another format. This is will include changes to the dictionaires defined in `maketaqparams`. For instance, it is simple to update if a user loaded trade data from a different source with new column names.
````
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
````
In this example, we would be interested to change the headers to only include the following ```` `ticktime`exch`sym`cond`size`price`parttime ````. To achieve this, the following changes were made:
````
    tradeparams:defaults,(!) . flip (
        (`headers;`ticktime`exch`sym`cond`size`price`parttime);
        (`types;"JSSSIF      J");
        (`tablename;`trade);
        (`separator;enlist"|");
        (`dbdir;hdbdir);             // this parameter is defined in the top level taqloader script
        (`symdir;symdir);            // where we enumerate against
        (`tempdb;tempdb);
        (`dataprocessfunc;{[params;data] `sym`ticktime`exch`cond`size`price xcols delete from
        (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data) where null ticktime});
        (`date;.z.d)
    );
````
Now once trade data is decompressed and loaded, it will have the following schema:
````
q)meta trade
c       | t f a
--------| -----
date    | d    
sym     | s    
ticktime| p    
exch    | s    
cond    | s    
size    | i    
price   | f    
parttime| p 
````
## Example ##
Here we just want to load in the NYSE trade data for date partition 2022.10.03 and manually move it to the HDB

1. Begin by downloading EQY_US_ALL_TRADE_20221003.gz from the NYSE website directly into your filedrop directory whilst your stacks are up
  
    `wget https://ftp.nyse.com/Historical%20Data%20Samples/DAILY%20TAQ/EQY_US_ALL_TRADE_20221003.gz`

2. After this download is complete, the orchestrator will pick up on this file and begin to decompress it within a taqloader process - an example log of this is shown below 
 ````
 2023.02.07D16:13:04.283306000|homer.aquaq.co.uk|orchestrator|orchestrator1|INF|alerter|running filealerter process
2023.02.07D16:13:04.283375000|homer.aquaq.co.uk|orchestrator|orchestrator1|INF|alerter|searching for /home/user/deploy/data/filedrop/*.gz
2023.02.07D16:13:07.537137000|homer.aquaq.co.uk|orchestrator|orchestrator1|INF|alerter|found file /home/user/deploy/data/filedrop/EQY_US_ALL_TRADE_20221003.gz
2023.02.07D16:13:07.537172000|homer.aquaq.co.uk|orchestrator|orchestrator1|INF|alerter|running function runload on /home/user/deploy/data/filedrop/EQY_US_ALL_TRADE_20221003.gz
2023.02.07D16:13:07.537276000|homer.aquaq.co.uk|orchestrator|orchestrator1|INF|runload|Initiating loader process
2023.02.07D16:13:07.537313000|homer.aquaq.co.uk|orchestrator|orchestrator1|INF|alerter|adding /home/user/deploy/data/filedrop/EQY_US_ALL_TRADE_20221003.gz to alreadyprocessed table
2023.02.07D16:13:07.537322000|homer.aquaq.co.uk|orchestrator|orchestrator1|INF|alerter|saving alreadyprocessed table to disk  
 ````
3. Once the trade file has finished loading in, we can locate it within `deploy/tempdb/final/2022.10.03/trade`
````
hdb
└── sym
tempdb
└── final
    └── 2022.10.03
        └── trade
            ├── cond
            ├── corr
            ├── cts
            ├── exch
            ├── parttime
            ├── price
            ├── sequence
            ├── size
            ├── stop
            ├── sym
            ├── ticktime
            ├── tradeid
            └── trf
````

4. Because we have only downloaded the trade data for this date, we would need to call the manualmovetohdb function inside the orchestrator process
````
q)/ connect to orchestrator process
q)h:hopen`::10612:admin:admin 
q)h"manualmovetohdb"
{[date;filetype]
    h:.servers.getserverbytype[`gateway;`w;`any];
        .lg.o[`startmovetohdb;"Moving ",(string filetype), " to hdb"]
        (neg h)(`.gw.asyncexecjpt;(`manmovetohdb;date;filetype);`qmerger;{x};..
  }
q)h"manualmovetohdb[2022.10.03;`trade]"
````
Now the data should be moved from the tempdb to the hdb directory
````
hdb
├── 2022.10.03
│   └── trade
│       ├── cond
│       ├── corr
│       ├── cts
│       ├── exch
│       ├── parttime
│       ├── price
│       ├── sequence
│       ├── size
│       ├── stop
│       ├── sym
│       ├── ticktime
│       ├── tradeid
│       └── trf
└── sym
tempdb
└── final
    └── 2022.10.03
````


>An overview blog [is here](https://www.aquaq.co.uk/q/torq-taq-a-nyse-taq-loader/), further documentation is in the docs [directory](docs/torqtaqtutorial.md). 
