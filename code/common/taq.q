maketaqparams:{
    tradeparams::defaults,(!) . flip (
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
    quoteparams::defaults,(!) . flip (
        (`headers;`ticktime`exch`sym`bid`bidsize`ask`asksize`cond`sequence`bbo`qbbo`cqs`rpi`shortsale`utpind`parttime);
        (`types;"JSSFIFISJCC  CCCC  J");
        (`tablename;`quote);
        (`separator;enlist"|");
        (`dbdir;hdbdir);               // this parameter is defined in the top level taqloader script
        (`symdir;symdir);              // where we enumerate against
        (`tempdb;tempdb);
        (`dataprocessfunc;{[params;data]
        `sym`ticktime`exch`bid`bidsize`ask`asksize`cond`mmid`bidexch`askexch`sequence`bbo`qbbo`corr`cqs`rpi`shortsale`cqsind`utpind`parttime xcols
            update mmid:(count ticktime)#enlist "",bidexch:`,askexch:`,corr:" ",cqsind:" " from
              delete from
              (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data)
              where null ticktime});
        (`date;.z.d)
    );
    nbboparams::defaults,(!) . flip (
        (`headers;`ticktime`exch`sym`bid`bidsize`ask`asksize`cond`sequence`bbo`qbbo`cqs`qcond`bbex`bbprice`bbsize`bbmmid`baex`baprice`basize`bammid`luldind`nbboind`parttime);
        (`types;"JSSFIFISJCC  CCCFI*CFI*CC J");
        (`tablename;`nbbo);
        (`separator;enlist"|");
        (`dbdir;hdbdir);             // this parameter is defined in the top level taqloader script
        (`symdir;symdir);            // where we enumerate against
        (`tempdb;tempdb);
        (`dataprocessfunc;{[params;data] 
	    `sym`ticktime`exch`bid`bidsize`ask`asksize`cond`mmid`bidexch`askexch`sequence`bbo`qbbo`corr`cqs`qcond`bbex`bbprice`bbsize`bbmmid`bbmmloc`bbmmdeskloc`baex`baprice`basize`bammid`bammloc`bammdeskloc`luldind`nbboind`parttime xcols 
	    // add in blank fields which don't exist any more 
 	      update mmid:(count ticktime)#enlist "",bidexch:`,askexch:`,corr:" ",bbmmloc:`,bbmmdeskloc:" ",bammloc:`,bammdeskloc:" " from 
 	        delete from 
	        (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data) 
	        where null ticktime});
        (`date;.z.d)
    );
  }

emptytaqschema:{
    trade:([] ticktime:`timestamp$();exch:`symbol$();sym:`symbol$();cond:`symbol$();size:`int$();price:`float$();stop:`boolean$();corr:`int$();sequence:`long$();tradeid:`int$();cts:`char$();trf:`char$();parttime:`timestamp$());
    quote:([] ticktime:`timestamp$();exch:`symbol$();sym:`symbol$();bid:`float$();bidsize:`int$();ask:`float$()asksize:`int$();cond:`symbol$();sequence:`long$();bbo:`char$();qbbo:`char$();cqs:`char;rpi:`char$();shortsale:`char$();utpind:`char$();parttime:`timestamp$());
    nbbo:([] sym:`symbol$();ticktime:`timestamp$();exch:`symbol$();bid:`float$();bidsize:`int$();ask:`float$();asksize:`int$();cond:`symbol$();sequence:`long$();bbo:`char$();qbbo:`char$();cqs:`char$();qcond:`char$();bbex:`char$();bbprice:`float$();bbsize:`int$();baex:`char$();baprice:`float$();basize:`int$();bammid:`char$();bammloc:`symbol$();bammdeskloc:`char$();luldind:`char$();nbboind:`char$();parttime:`timestamp$());
    emptyschemas::`trade`quote`nbbo!(trade;quote;nbbo)
  }