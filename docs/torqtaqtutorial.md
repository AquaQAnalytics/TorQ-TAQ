<a name="TorQ-TAQ Tutorial"></a>

# TorQ-TAQ Tutorial

The TorQ-TAQ repository provides a set of extensions to the TorQ architecture. Instructions to install and launch a TorQ stack can be found [here](https://github.com/AquaQAnalytics/TorQ).

## Getting Started
To install TorQ-TAQ, download the code from the repository [here](https://github.com/AquaQAnalytics/TorQ-TAQ). The functionality of TorQ-TAQ can be tested using dummy data downloaded directly from the NYSE website [here](ftp://ftp.nyxdata.com/Historical%20Data%20Samples/Daily%20TAQ%20Sample%202018/).

## Configuration Settings
Each of the processes available in TorQ-TAQ are configurable via settings in the `appconfig/settings` directory. Listed below are descriptions of the configuration settings available for each process.

### Orchestrator

`optionalparams` - dictionary containing any optional parameters required for use in the taqloader function.

`loadfiles` - symbol-type list of the files to be loaded. These must be of the type `trade`,`quote`, or `nbbo`.  File types not listed here will not be loaded by the TAQ loader.

`forceload` - Boolean variable determining whether the loader process will reload a file which has already been successfully loaded. Loaded files are recorded in the `fileloading` table in 
the orchestrator (see [Checking Monitoring Statistics](#Checking-Monitoring-Statistics) below). This variable can be manually overwritten in the q process.

### TAQ Loader

`hdbdir` - location of the hdb directory in your TorQ codebase. All loaded data will be saved here once file loading has completed.

`symdir` - location of the sym file used to enumerate loaded data. By default, this will be the hdb directory, but this can be adjusted as necessary.

`tempdb` - temporary directory the data is sent to upon loading. As the data is loaded and merged, it is first saved here, before being moved to the hdb when all files have been successfully loaded. The `manualmovetodhb` function defined in the orchestrator can be invoked to manually move the data before completion (see [Support/Manual Functions in Orchestator](#Support/Manual-Functions-in-Orchestator) below).

`filedrop` - directory that the orchestrator checks for new NYSE TAQ files. If a TAQ file is moved to this directory, the orchestrator will invoke a loader process and load the file accordingly.

### Merger

`hdbdir` - should be identical to the TAQ Loader `hdbdir`.

`tempdb` - should be identical to the TAQ Loader `tempdb`.

`mergedir` - location of the merged table containing the quote split files that have been successfully merged.

## Running TorQ-TAQ
TorQ-TAQ contains a directory called `filedrop`. TAQ files downloaded from the NYSE website can be moved to this directory. The stack is then initiated by running `./torq.sh start all` in the command line from the deploy directory, which will start all processes. The orchestrator process will detect the new files in `filedrop` and invoke the appropriate loader processes.

Additionally, TorQ has a `setenv.sh` file which contains all of the environment variables used in TorQ-TAQ.  Instructions on setting this up can be found [here](https://aquaqanalytics.github.io/TorQ/gettingstarted/)

## Checking Monitoring Statistics
The orchestrator process maintains monitoring statistics. To view these, open a handle to this process and check the `fileloading` table.  You may open a handle using `qcon` in the command line or open a q process and open a handle using:

```
$~ qcon :portnumber:user:pass
q)h:hopen`::portnumber:user:pass
```

An example of what this table might look like:

```
q)fileloading
loadid| filename                        filetype split loadstarttime                 loadendtime                   loadstatus loadmessage                                                                          mergestarttime                mergeendtime                  mergestatus mergemessage
------| -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1     | SPLITS_US_ALL_BBO_A_20180103.gz quote    A     2020.06.11D23:24:38.594216000 2020.06.12D00:24:38.596325000 0          "error: the following are not valid servers: taqloader. Available servers include: "                                                             0
2     | SPLITS_US_ALL_BBO_A_20180103.gz quote    A     2020.06.11D23:26:33.628382000 2020.06.12D00:27:57.486390000 1          "success"                                                                            2020.06.12D00:27:57.490433000 2020.06.12D00:27:57.494166000 0
```

A description of each of the `fileloading` fields is given below:

**loadid** - Unique ID for each load attempt.

**filename** - Name of the .gz file to be loaded.

**filetype** - Type of file, i.e. trade, quote, or nbbo.

**split** - If the file is a quote, this will display the split letter.

**loadstarttime** - Time at which the load started.

**loadendtime** - Time at which the load completed.

**loadstatus** - Binary indicator showing if load was successful (takes value 1) or unsuccessful (0). 

**loadmessage** - Displays the error message if the load was halted by an error, shows "success" otherwise.

**mergestarttime** - If the file is quote, this will display the start time of the merge.

**mergeendtime** - Time at which the merge of the split file is completed.

**mergestatus** - Binary indicator showing if the merge was successful (takes value 1) or
 unsuccessful (0).

**mergemessage** - Displays the error message if the merge was halted by an error, shows "success" otherwise.

## Support/Manual Functions in Orchestator

`manualmovetohdb` - This function can be called with arguments `[date;filetype]` in the orchestrator to manually move loaded data to the hdb. `date` is a date type and `filetype` is a symbol (one of `trade`,`quote`, or `nbbo`). By default, data is only moved when all files have been successfully loaded and merged. However, this can be called to move the data at a different point in time.  

## Running Tests

The TorQ-TAQ `tests` directory contains the relevant k4unit tests made for each TorQ-TAQ process.  To run each of these tests, run the code below in the command line.  It is important to note that the TAQ Loader tests must be executed first, and then the merger tests second.  The functionality of the merger is dependent on files being loaded using the loader process, and thus it will fail if the loader has not already run. Also, make sure to download the sample data from [here](ftp://ftp.nyxdata.com/Historical%20Data%20Samples/Daily%20TAQ%20Sample%202018/) as described above. The tests require the following files to be downloaded and moved to the directory `tests/taqfiles`:

- `EQY_US_ALL_NBBO_20180306.gz` 
- `EQY_US_ALL_TRADE_20180305.gz`
- `SPLITS_US_ALL_BBO_A_20180103.gz`

- TAQ Loader Tests: `q torq.q -load code/processes/taqloader.q -proctype taqloader -procname taqloader1 -test tests/taqloader -debug`
- Merger Tests: `q torq.q -load code/processes/qmerger.q -proctype qmerger -procname qmerger1 -test tests/qmerger -debug`
- Orchestrator Tests: `q torq.q -load code/processes/orchestrator.q -proctype orchestrator -procname orchestrator1 -test tests/orchestrator -debug`

### TAQ Loader Tests
The tests in the TAQ loader will test each function within the `taqloader.q` file. The TAQ loader invokes the loading of data from each type of file (trade, quote, nbbo). Because of this, the unit test will generate a hdb and a temphdb in the test directory. The TAQ Loader tests in `taqloader.csv` references a `SPLITS_US_ALL_BBO_X_20180103.gz` which has not been downloaded.  This is to test the functionality of the loader when the file does not exist.  A similar tests is done for a file with an incorrect date when the test references the file `SPLITS_US_ALL_BBO_A_2018010A.gz`.


