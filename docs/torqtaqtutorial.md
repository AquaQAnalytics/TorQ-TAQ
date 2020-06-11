<a name="TorQ-TAQ Tutorial"></a>

# TorQ-TAQ Tutorial

After installing a TorQ stack, you will be able to use all of the extensions available
in TorQ-TAQ.  You can find the download for TorQ [here](https://github.com/AquaQAnalytics/TorQ).

## Getting Started
To install TorQ-TAQ, grab the code from the repo [here](https://github.com/AquaQAnalytics/TorQ-TAQ).
Then, if you want to test the functionality of TorQ-TAQ, you can download some
dummy data directly from the NYSE website [here](ftp://ftp.nyxdata.com/Historical%20Data%20Samples/Daily%20TAQ%20Sample%202018/).

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

**loadid** - The unique ID for each load attempt

**filename** - The name of the .gz file to be loaded

**filetype** - type of file, i.e. trade, quote, or nbbo

**split** - if the file is a quote, the split letter will be displayed here

**loadstarttime** - the time the load started

**loadendtime** - the time at which the load completed

**loadstatus** - binary indicator showing if load was successful or not.  1 indicates the load was successful and 0 indicates it was not successful.

**loadmessage** - if the load was successful, this will contain the string `"success"`.  If the load encountered an error at any point, the error is caught and displayed here as a string.

**mergestarttime** - if the file is quote, the start of the merge will be displayed here

**mergeendtime** - the time the merge of the split file is completed

**mergestatus** - binary indicator showing if the merge was successful or not.  1 indicates the merge was successful and 0 indicates it was not successful.

**mergemessage** - if the merge encounters an error, the error message will be displayed here.

