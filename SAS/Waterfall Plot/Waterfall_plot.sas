/***********************************

************************************/

***** Filtering only post baseline records, only subjects from SAF population, only necessary parameters *****;
data ADLBC;
	set adam.adlbc(where = (paramcd in ('GGT') and saffl = 'Y' and avisitn > 0));
	
	if not nmiss(aval,base) then pchg = (aval-base)/base * 100;
	
run;

proc sql noprint;
	
	***** Generating a data set with maximum percentage change for each subject *****;
	create table MaxPchgs1 as select max(pchg) as MaxPchg, trta, usubjid from ADLBC where pchg ^= . group by trta, usubjid order by trta, MaxPchg desc;
	
quit;

****** The main data set *****;
data MaxPchgs2;
	set MaxPchgs1;
	by trta descending MaxPchg;
	
	if first.trta then xValues = 1;
	else xValues + 1;
	
	if MaxPchg > 100 then do;
		MaxPchg = 100;
		ULOQ = 105;
	end;
	
run;

proc sgpanel data = MaxPchgs2 noautolegend;
	panelby trta / rows = 3 novarname;
	
	***** Titles *****;
	title1 "Waterfall Plot of Maximum Post Baseline Percentage Change in GGT (Safety Analysis Set)";
	
	***** The plot ******;
	vbar xValues / response = MaxPchg group = trta;
	Vline xValues / response = ULOQ group = trta markers markerattrs = (symbol = union size = 4 color=black) lineattrs = (thickness = 0);
	
	***** Axis options ******;
	rowaxis label = "Maximum post baseline percentage change" minor minorcount=4 type = linear;
	colaxis display = none type = discrete;
	
	***** Footnotes *****;
	footnote1 justify = left height = 0.95 "Each bar represents unique subject's maximum percentage change.";
	footnote2 justify = left height = 0.95 "If subject's maximum percentage change was greater than 100 percent then the change was displayed as 100 and indicated with the letter U in plot. GGT = Gamma-glutamyltransferase.";
	
run;
