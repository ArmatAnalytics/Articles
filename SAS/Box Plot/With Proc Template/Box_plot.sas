/***********************************

************************************/

proc template;
	***** Defining boxplot template *****;;
	define statgraph boxplot;
	
		***** Defining dynamic variables (template for boxplot) *****;
		dynamic _title _x _y _ylabel _xlabel;
		begingraph;
			
			***** Title *****;
			entrytitle _title;
			
			***** Appearance options *****;
			discreteattrmap name = "colors"/ ignorecase = true;
				*** Marker, fill, and line colors ***;
				value "Placebo" / markerattrs = (color = MidnightBlue) fillattrs = (color = SteelBlue) lineattrs = (color = MidnightBlue);
				value "Xanomeline Low Dose" / markerattrs = (color = DarkGreen) fillattrs = (color = LightGreen) lineattrs = (color = DarkGreen);
				value "Xanomeline High Dose" / markerattrs = (color = SaddleBrown) fillattrs = (color = Khaki) lineattrs = (color = SaddleBrown);
			enddiscreteattrmap;
			
			*** Assigning attribute map "colors" to the TRTA variable ***;
			discreteattrvar attrvar=trta_map var=trta attrmap="colors";
			
			**** Generating the plot area *****;
			layout overlay/ xaxisopts=( label = _xlabel type = discrete) yaxisopts=( label = _ylabel type = linear );
				***** The plot *****;
				boxplot X = _x Y = _y / group = trta_map groupdisplay = cluster name = "box";
				***** Legend *****;
				discretelegend "box" / title = "Treatment Groups:";
			endlayout;
			
		endgraph;
		
	end;
run;


***** Dynamically rendering the boxplot template to the desired data to be plotted *****;

proc sgrender data = adam.adlbc(where=(paramcd="SODIUM")) template=boxplot;
	* giving values and variables names to use in the plot;
	dynamic _x = "avisitn" 
			_y = "aval"
			_ylabel = "Sodium (mmol/L)"
			_title = "Test Results for Sodium in Each Visit"
			_xlabel = "Visit"
			;
run;
