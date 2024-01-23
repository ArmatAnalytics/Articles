/***********************************

************************************/

***** Filtering only post baseline records, only subjects from SAF population, only necessary parameters *****;
data adlbc;
	set adam.adlbc;
	where avisitn > 0 and saffl="Y" and paramcd in ("BILI","ALT");
run;

proc sql noprint;
	
	***** Number of subject is each treatment group (for titles) *****;
	create table N_Subjs as select count(distinct usubjid) as N_sbjs, trt01a from adam.adsl where saffl = 'Y' group by trt01a;
	
	***** Creating macro variables which contain the values of upper (lower) limits of parameter's normal range.
		  If more than one upper (lower) limit exists the minimum (maximum) limit has been taken *****;
	select min(a1hi),  max(a1lo) into :RefLineH1 - :RefLineH2, :RefLineL1 - :RefLineL2 from adlbc group by paramcd order by paramcd;
	
	***** Generating a data set with maximum result for each subject and parameter to be plotted *****;
	create table MaxRslts1 as select max(aval) as maximum, trta, paramcd, usubjid from adlbc group by paramcd, trta, usubjid;
	
	***** Adding the number of subjects in the main data set *****;
	create table MaxRslts2 as select maximum, catx(' ',trta,cats('(N=',N_sbjs,')')) as trt_With_N, paramcd, usubjid from MaxRslts1 left join N_subjs on trta = trt01a order by trt_With_N, usubjid;
	
	***** Creating macro variables to hold the minimum values of maximum results for both parameters. Will be used to define the minimum axes display values. *****;
	select min(maximum) into :min1 - :min2 from MaxRslts2 group by paramcd order by paramcd;
	
quit;

***** Minimum of refline and data values ******;
%let xmin = %sysfunc(min(&min1.,&reflinel1.));
%let ymin = %sysfunc(min(&min2.,&reflinel2.));

***** Printing the values of created macro variables in the LOG for a quick check *****;
%put &=xmin. &=ymin. &=RefLineH1. &=RefLineH2. &=RefLineL1. &=RefLineL2. &=min1. &=min2.;

***** Generating the fundamental data for plot with the necessary structure *****;
proc transpose data = MaxRslts2 out = DataForPlot(drop = _name_);
	by trt_With_N usubjid;
	id paramcd;
	var maximum;
run;

***** Drawing the graph. SGPANEL was used to generate more than one plot on the single page (for each treatment group) *****;
proc sgpanel data = DataForPlot noautolegend;
	
	* Three plots (since 3 treatments) generated horizontally. To generated vertically the values of COLUMNS and ROWS options should be replaced *; 
	panelby trt_With_N / columns = 3 rows = 1 novarname;
	
	title "Scatter Plot of Total Bilirubin vs. ALT (Safety Analysis Set)";
	
	
	styleattrs datacolors = (red blue orange) datasymbols = (circlefilled) datacontrastcolors = (black);
	* The plot *;
	scatter x = Alt y = Bili / group = trt_With_N filledoutlinedmarkers;
	
	* Y and X axes' labels, logarithmic scaling *;
	rowaxis label = "Maximum post baseline total bilirubin" type = log logbase = e logstyle = linear min = &ymin. logvtype = expanded;
	colaxis label = "Maximum post baseline ALT" type = log logbase = e logstyle = linear min = &xmin. logvtype = expanded;
	
	* Reference lines (horizontal and vertical) on y and x axes *;
	refline &RefLineH1. &RefLineL1. / lineattrs=(pattern=dash) axis=x;
	refline &RefLineH2. &RefLineL2. / lineattrs=(pattern=dash) axis=y;
	
	* Footnotes *;
	footnote1 justify=left height=0.95 "Each data point represents a unique subject.";
	footnote2 justify=left height=0.95 "Logarithmic scaling was used on both X and Y axis.";
	
run;
