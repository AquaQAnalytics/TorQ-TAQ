# TorQ-TAQ
NYSE TAQ Loader in using kdb+ and TorQ

# Quick Installisation

To download TorQ TAQ, get latest installation script and download it to the directory where you want your codebase to live

`wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ-TAQ/master/installlatest.sh`

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
│   ├── data -> ~/torq/datatemp
│   ├── TorQ
│   └── TorQApp
├── installlatest.sh
├── installtorqapp.sh
├── TorQ-4.3.0.tar.gz
└── TorQ-TAQ-1.0.0.tar.gz
````
An overview blog [is here](https://www.aquaq.co.uk/q/torq-taq-a-nyse-taq-loader/), further documentation is in the docs [directory](docs/torqtaqtutorial.md). 
