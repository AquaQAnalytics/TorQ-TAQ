<a name="TorQ-TAQ Tutorial"></a>

# TorQ-TAQ Tutorial

After installing a TorQ stack, you will be able to use all of the extensions available
in TorQ-TAQ.  You can find the download for TorQ [here](https://github.com/AquaQAnalytics/TorQ).

## Getting Started
To install TorQ-TAQ, grab the code from the repo [here](https://github.com/AquaQAnalytics/TorQ-TAQ).
Then, if you want to test the functionality of TorQ-TAQ, you can download some
dummy data directly from the NYSE website [here](ftp://ftp.nyxdata.com/Historical%20Data%20Samples/Daily%20TAQ%20Sample%202018/).

## Configuration Settings
Each of the processes available in TorQ-TAQ contain configurable settings in the
`appconfig/settings` directory. Listed below are the settings which are configurable
for each TorQ-TAQ process and their purpose:

### Orchestrator

`optionalparams` - a dictionary which contains any optional parameters you might
use for the taqloader function.

`loadfiles` - a list of symbols containing the files you are interested in.
These must be any of `trade`,`quote`,or `nbbo`.  File types not listed here
will not be loaded by the TAQ loader.

`forceload` - a booleon variable indicating whether you will let the loader
process reload a file even though it has already been successfully loaded as 
indicated in the `fileloading` table in the orchestrator.  This can be set in the
configuration file in `appconfig/settings/orchestrator.q` or overwritten in the 
q process

### TAQ Loader

`hdbdir` - the directory of the hdb in your TorQ stack.  All loaded data will 
be sent here upon completion.

`symdir` - the directory which the loaded data will be enumerated against.  
By default this will be the hdb, but can be adjusted as necessary.

`tempdb` - the temporary directory the data is sent to upon loading.  As the data
is loaded and merged, it is first loaded into this directory. The data will only
move to the hdb when all files have been successfully loaded, unless manually sent
by the `manualmovetodhb` function defined in the orchestrator which is documented
below.

`filedrop` - the directory that the orchestrator checks for new NYSE TAQ files.
If a TAQ file is moved to this directory, the orchestrator will invoke a loader
process and load the file accordingly.

### Merger

`hdbdir` - this should be the same as the TAQ Loader `hdbdir`.

`tempdb` - this should be the same as the TAQ Loader `tempdb`.

`mergedir` - location of the merged table containing the quote split files that 
have been successfully merged.

## Running TorQ-TAQ
TorQ-TAQ contains a directory called `filedrop`. You may move or copy the TAQ
files that you downloaded from the NYSE website to this directory.  Once the 
files have been moved here. You may start the stack by running `./torq.sh start all`
in the command line.  This command will start all processes, including the
orchestrator which will detect the new files in `filedrop` and invoke some
loader processes.

## Checking Monitoring Statistics
If you wish to see the monitoring statistics located in the orchestrator
process, you may open a handle to this process and check the `fileloading` table.
An example of what this table might look like is:

```
q)fileloading
loadid| filename                        filetype split loadstarttime                 loadendtime                   loadstatus loadmessage                                                                          mergestarttime                mergeendtime                  mergestatus mergemessage
------| -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1     | SPLITS_US_ALL_BBO_A_20180103.gz quote    A     2020.06.11D23:24:38.594216000 2020.06.12D00:24:38.596325000 0          "error: the following are not valid servers: taqloader. Available servers include: "                                                             0
2     | SPLITS_US_ALL_BBO_A_20180103.gz quote    A     2020.06.11D23:26:33.628382000 2020.06.12D00:27:57.486390000 1          "success"                                                                            2020.06.12D00:27:57.490433000 2020.06.12D00:27:57.494166000 0
```

Though most of the fields' meanings are obvious, a description of each are:

**loadid** - The unique ID for each load attempt.

**filename** - The name of the .gz file to be loaded.

**filetype** - type of file, i.e. trade, quote, or nbbo.

**split** - if the file is a quote, the split letter will be displayed here.

**loadstarttime** - the time the load started.

**loadendtime** - the time at which the load completed.

**loadstatus** - binary indicator showing if load was successful or not.  1 
indicates the load was successful and 0 indicates it was not successful.

**loadmessage** - if the load was successful, this will contain the string 
`"success"`.  If the load encountered an error at any point, the error is caught
and displayed here as a string.

**mergestarttime** - if the file is quote, the start of the merge will be displayed
here.

**mergeendtime** - the time the merge of the split file is completed.

**mergestatus** - binary indicator showing if the merge was successful or not.
1 indicates the merge was successful and 0 indicates it was not successful.

**mergemessage** - if the merge encounters an error, the error message will be 
displayed here.

## Support/Manual Functions in Orchestator

`manualmovetohdb` - This function can be manually called with arguments `[date;filetype]`
in the orchestrator to manually move loaded data to the hdb. `date` is a date
type and `filetype` is a symbol which is one of `trade`,`quote`, or `nbbo`.  By
default, data is only moved when all data is successfully loaded and merged; 
however, this can be called if you wish to move the data at a different point in
time.  

## Running Tests

In the TorQ-TAQ `tests` directory you will find the relevant k4unit tests made 
for each TorQ-TAQ process.  To run each of these tests, run the code below in 
the command line.  It is important to note that you should run the TAQ Loader 
tests first, and then the merger tests second.  This is because the functionality 
of the merger is dependent on files being loaded using the loader process in the first place. Also, 
make sure to download the sample data [here](ftp://ftp.nyxdata.com/Historical%20Data%20Samples/Daily%20TAQ%20Sample%202018/) 
as listed earlier; make sure to download the following files to `tests/taqfiles`:

- `EQY_US_ALL_NBBO_20180306.gz`
- `EQY_US_ALL_TRADE_20180305.gz`
- `SPLITS_US_ALL_BBO_A_20180103.gz`

- TAQ Loader Tests: `q torq.q -load code/processes/taqloader.q -proctype taqloader -procname taqloader1 -test tests/taqloader -debug`
- Merger Tests: `q torq.q -load code/processes/qmerger.q -proctype qmerger -procname qmerger1 -test tests/qmerger -debug`
- Orchestrator Tests: `q torq.q -load code/processes/orchestrator.q -proctype orchestrator -procname orchestrator1 -test tests/orchestrator -debug`

### TAQ Loader Tests
The tests in the TAQ loader will test each function within the `taqloader.q` file which involves loading data from each type of file (trade, quote, nbbo).  Because of this, the test directory will have its own test hdb and tempdb.