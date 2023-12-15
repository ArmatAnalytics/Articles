/***********************************

************************************/

proc format;
	***** Defining a format to convert a specific numeric value to something else but leave others the same ******;
	value noDot . = "NA" other = [best.];	
run;

***** Filtering only post baseline and baseline records, only subjects from SAF population, only necessary parameters *****;
data adlbc;
	set adam.adlbc;
	where avisitn >= 0 and paramcd in ('ALT','AST') and saffl = "Y";
	
	keep usubjid chg trta param paramcd a1hi aval ady;
run;

proc sql noprint;
***** Creating macro variables which contain the values of upper limits of parameter's normal range.
		  If more than one upper limit exists the minimum limit has been taken *****;
	select min(a1hi) into :RefLineH1 - :RefLineH2 from adlbc group by paramcd order by paramcd;
quit;	

options nobyline missing = "N";
				*^^^^^^^^^^^^^* Option to change the value of missing from "."" to "N";	

proc sgplot data = adlbc;
	by usubjid trta;
	/*format chg noDot.;*/
	
	title1 "ALT and AST Results Over Time. (Safety Analysis Set)";
	title2 "Subject: #byval(usubjid), Treatment: #byval(trta)";
	
	***** The plot *****;
	styleattrs datasymbols=(circle star) datacontrastcolors=(purple green) datalinepatterns=(ShortDash LongDash);
	series x = ady y = aval  / markers group = paramcd groupmc = paramcd groupms = paramcd grouplp = paramcd name = "SeriesPlot";
	
	xaxis type = discrete grid label="Study day relative to treatment start day";
	yaxis grid label = "Analysis value";
		
	***** Listing of changes from baseline *****;
    xaxistable chg / class = paramcd /*nomissingchar*/ title = 'Change from baseline';
	
	keylegend 'SeriesPlot' / position=bottom location = outside;
	
	refline &RefLineH1. &RefLineH2. / noclip label = ('ALT ULN' 'AST ULN') labelattrs = (color = black family=Arial size=4 style=Italic);
	
	footnote justify=left height=0.95 "AST = Aspartate Aminotransferase (U/L). ALT = Alanine Aminotransferase (U/L). ULN = Upper Limit Normal.";
run;
