/*
A = importing of dataset 
*/

proc import DATAFILE = "/home/u63273011/AN PROJECT ON SAS/Weight_loss (1).xlsx"
	DBMS = xlsx
	OUT = WLO;
run;


/*
B = data managment
*/
/*1 = check data*/
proc means DATA = WLO MAXDEC=1;
run;

proc freq DATA = WLO;
TABLE weight0-weight2 walk_steps/MISSING ;
run;
/*unrelated values of this procedure mainly to weight1 and weight2 because of 9999 observation*/


/*2 = clean data*/
/*3 = Create weight difference variables*/
data WL1(DROP = i);
SET WLO;
	ARRAY weight{3} weight0-weight2;
	ARRAY wd{3} wd1 wd2 wd12;
	DO i = 1 to 3;
		IF weight{i} = 9999 THEN weight{i} = '.'; /*add missing value in place of 9999*/
	END;
	wd1 = weight0 - weight1;
	wd2 = weight0 - weight2;
	wd12 = weight1 - weight2;
run;

	/*same function we can run by using proc sql programm*/
proc sql;
	CREATE TABLE WL AS
	SELECT *,
		   weight0 - weight1 AS wd1,
		   weight0 - weight2 AS wd2,
		   weight1 - weight2 AS wd12
	FROM WLO 
	WHERE weight0 ne 9999 AND weight1 ne 9999 AND weight2 ne 9999; /*removal of missing value in place of 9999*/
quit;


/*4 = select proc means, proc freq for variable wd2*/	
	/*we can take other variable for practice letter*/	
	/*
	Using Proc Means and Proc Freq, check weight difference variables and walk_steps var for making groups from these var. 
	*/
proc means DATA = WL1 MAXDEC=1 MISSING;
VAR wd2 walk_steps;
TITLE 'means procedure for wd2';
run;
/*one thing i found here is proc mean showing only 18 observation rather that 19*/

proc freq DATA = WL1;
TABLE wd2*walk_steps/missing NOCOL NOROW NOPERCENT;
TITLE 'freq procedure for wd2 VS walk_steps';
run;


/*5 = create groups for walk_steps: create new var ws_group
	the new group var should have 3 categories:
	less than 5000
	'5000-10000'
	greater than 10000
*/
data WL1;
SET WL1;
LENGTH ws_group $20;
	IF walk_steps >10000 THEN DO
		ws_group =  "greater than 10000";
		END;
	ELSE IF walk_steps =>5000 THEN DO
		ws_group = "5000-10000";
		END;
	ELSE IF walk_steps < 5000 THEN DO
		ws_group = "less than 5000";
		END;
	ELSE ws_group = "Missing";
run;

/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
/*6 = create groups for wd2: create new var wd2_group
	the new group var should have 3 categories:
	not losing weight
	losing <= 5 lb
	losing > 5 lb
*/
data WL2;
SET WL1;
LENGTH wd2_group $20;
	IF wd2 > 5 THEN DO
		wd2_group = "losing > 5 lb";
		END;
	ELSE IF 0 < wd2 <= 5 THEN DO
		wd2_group = "losing <= 5 lb";
		END;
	ELSE IF wd2 ne '.' AND wd2 <= 0 THEN DO
		wd2_group = "not losing weight";
		END;
	ELSE wd2_group = "missing";
run;

	
/*
C = Create permanent data set from data set WL2: projectd.weight_loss
*/
LIBNAME projectd "/home/u63273011";

data projectd.weight_loss;
SET WL2;
run;


/*
D = create cross-tab using Proc Freq for walk steps' groups 
	(walk_steps_G) and weight loss groups (loss_weight_G) to exam the possible trend
*/	
proc freq DATA = projectd.weight_loss;
TABLE wd2_group ws_group ws_group*wd2_group/NOCOL NOROW NOPERCENT;
TITLE "weight diff from 2 months vs daily walking steps : correlation"; 
run;

proc sgplot data=projectd.weight_loss;
   loess x=walk_steps y=wd2;
   xaxis label="Walking Steps";
   yaxis label="Weight_Diff two months";
   title "Trend Line of Weight Diff from 2 Months vs. Daily Walking Steps: Correlation";
run;
/*
...................................... findings = more than 10000_steps has significant decrease in >5 lb of weight loss
...................................... ie. High walking_steps per day = significant weight loss after 2 months
also at medium walking_steps it decreases the weight in some extent in some peoples
*/

/* gender wise effect of walking on wd2_group*/
proc sort DATA = projectd.weight_loss OUT = weight_loss_sort;
by gender;
run;

proc freq DATA = weight_loss_sort;
TABLE ws_group*wd2_group/NOCOL NOROW NOPERCENT;
BY gender;
TITLE 'weight diff from 2 months vs daily walking steps : by gender';
run;
/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/


/*6 = create groups for wd1: create new var wd1_group
	the new group var should have 3 categories:
*/
data WL3;
SET WL1;
LENGTH wd1_group $20;
	IF wd1 > 5 THEN DO
		wd1_group = "losing > 5 lb";
		END;
	ELSE IF 0 < wd1 <= 5 THEN DO
		wd1_group = "losing <= 5 lb";
		END;
	ELSE IF wd1 ne '.' AND wd1 <= 0 THEN DO
		wd1_group = "not losing weight";
		END;
	ELSE wd1_group = "missing";
run;

proc freq DATA = WL3;
TABLE wd1_group ws_group ws_group*wd1_group/NOCOL NOROW NOPERCENT;
TITLE "weight diff from 1 months vs daily walking steps : correlation"; 
run;

proc sgplot DATA = WL3;
	LOESS X=walk_steps Y=wd1;
	XAXIS LABEL="walking_steps";
	YAXIS LABEL="weight_diff one month";
	TITLE "Trend Line of Weight Diff from 2 Months vs. Daily Walking Steps: Correlation";
run;
/*
...................................... findings = more than 10000 walking_steps has significant decrease in >5 lb weight 
									   loss
...................................... ie. High walking_steps per day = significant weight loss after 1 months
but for one month finding initialy for 5000-10000 steps weight is neutral or slightly effective
ie. only High walking_steps are significant for one month routine
*/
/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

	
data WL4;
SET WL1;
LENGTH wd12_group $20;
	IF wd12 > 5 THEN DO
		wd12_group = "losing > 5 lb";
		END;
	ELSE IF 0 < wd12 <= 5 THEN DO
		wd12_group = "losing <= 5 lb";
		END;
	ELSE IF wd12 ne '.' AND wd12 <= 0 THEN DO
		wd12_group = "not losing weight";
		END;
	ELSE wd12_group = "missing";
run;

proc freq DATA = WL4;
TABLE wd12_group ws_group ws_group*wd12_group/NOCOL NOROW NOPERCENT;
TITLE "weight diff from 1 months vs daily walking steps : correlation"; 
run;

proc sgplot DATA = WL4;
	LOESS X=walk_steps Y=wd12;
	XAXIS LABEL="walking_steps";
	YAXIS LABEL="weight_diff one month between";
	TITLE "Trend Line of Weight Diff from 1 Months vs. Daily Walking Steps: Correlation";
run;
/*
................................findings are very close to 2 month difference ie as number of steps increase = weight 
								decrease
*/		