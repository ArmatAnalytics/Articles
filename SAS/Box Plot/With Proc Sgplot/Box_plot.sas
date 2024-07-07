/***********************************

************************************/

***** Setting the domain ****;
data adlbc;
	set adam.adlbc;
run;

**** Drawing the box plot for Sodium records*****;
proc sgplot data=adlbc(where=(paramcd="SODIUM"));

	title "Test Results in Each Visit for SODIUM";
	styleattrs datacolors=( BIOY BRO Big ) datacontrastcolors=( BROWN BLACK darkgreen );
	
	* The plot *;
	vbox aval / category=avisitn group=trta;
	
	* Y and X axes' labels *;
	xaxis label="Visits";
	yaxis label="Sodium (mmol/L)";
	
	* Legend title *;
	keylegend / title="Treatment Groups: ";
run;
