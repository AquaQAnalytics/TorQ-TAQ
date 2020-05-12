<a name="TorQ-TAQ"></a>

Overview of TorQ-TAQ 
====================
Torq-TAQ is the name given to the New York Stock Exchange (NYSE) Trade and Quote (TAQ) Loader built in 
TorQ. The purpose of this architecture is to efficiently grab files containing
historical data from the NYSE and load them into kdb. TorQ-TAQ currently 
supports loading three types of files from the NYSE website; these files 
include: trades, national best bid offer (nbbo) and Best Bid Offer (quotes). 
All of the files from the NYSE website are .gz files and have the structure:

- `EQY_US_ALL_TRADE_YYYYMMDD.gz` *(trades)* 
- `EQY_US_ALL_NBBO_YYYYMMDD.gz` *(National Best Bid Offer)* 
- `SPLITS_US_ALL_BBO_*_YYYYMMDD.gz` *(Best Bid Offer - 26 files per day)* 

The specification for each of the file types can be found on the NYSE website 
[here](https://www.nyse.com/publicdocs/nyse/data/Daily_TAQ_Client_Spec_v3.2.pdf)

Architecture
============
