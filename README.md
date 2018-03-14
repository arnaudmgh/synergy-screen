# synergy-screen

## Purpose
This git repo contains the companion code the manuscript *Statistical Assessment of Synergy
in a Large Replicate-less Drug Combination Screen*, by Arnaud Amzallag, Julian Pruteanu-Malinici,
Adam A. Friedman, Daniel A. Haber, Sridhar Ramaswamy, David E. Fisher, Cyril H. Benes, from the MGH Cancer Center.

This script allows to reproduce, from raw data, the statistical analysis for the significance assessment of synergies in
the systematic drug screen performed at the MGH Cancer Center. The script is thoroughly commented and is intended to be
read and executed on the R prompt. It produces several diagnostic and explainatory figures. 
this code should:
* provide a transparent description of the methods used in the study
* expose a novel way of estimating single drugs viability for estimation of drug synergy
* facilitate follow-up analysis and exploration of the large combination data published with the study

In addition, it provide the code of a web app for rapid interactive visualization of the 439,128 drug combination
viabilities provided, which is available at http://www.cmtlab.org:3000/combo_app.html

## Usage

### Processing in R
To understand the processing and analysis steps from raw data, one can follow the commented script `combos_script.R`.
However, if you just want to obtain all the output files at once (including the necessary files to run the web app),
you can run the full script with
```
   Rscript combos_script.R
```
on the command line. It should take between 5 and 10 minutes to run. 

### Running the web application
* Run `combos_script.R` (see above) to produce the summarized data files that are used for the web visualization.
* Install [npm](https://docs.npmjs.com/getting-started/installing-node), since the web app is running on Node.js,
a lightweight web server written in javascript. 
* From the directory `combo_web`, run `rpm install` (you might need `sudo npm install`, on ubuntu for instance). 
* Run `node server.js`
* In a web browser, go to `http://localhost:3000/combo_app.html`
