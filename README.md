# synergy-screen

> **⚠️ WARNING:**  
> The new URL for the synergy-screen app is [https://synergy-screen.netlify.app/](https://synergy-screen.netlify.app/).  
> Please update your bookmarks

See [README_STATIC_CONVERSION.md](README_STATIC_CONVERSION.md) for details about the static site conversion process.

## Purpose
This git repo contains the companion code the manuscript *Statistical Assessment and Visualization of Synergies for Large-Scale Sparse Drug Combination Datasets*, by Arnaud Amzallag, Sridhar Ramaswamy, Cyril H. Benes, from the MGH Cancer Center.

This script allows to reproduce, from raw data, the statistical analysis for the significance assessment of synergies in
the systematic drug screen performed at the MGH Cancer Center. The script is thoroughly commented and is intended to be
read and executed on the R prompt. It produces several diagnostic and explainatory figures. 
this code should:
* provide a transparent description of the methods used in the study
* expose a novel way of estimating single drugs viability for estimation of drug synergy
* facilitate follow-up analysis and exploration of the large combination data published with the study

In addition, it provide the code of a web app for rapid interactive visualization of the 439,128 drug combination
viabilities provided, which is available at http://www.cmtlab.org:3000/combo_app.html

**NEW**: This repository also includes a static Hugo website version that provides the same visualization capabilities
without requiring a Node.js server. The static site can be deployed to any web hosting service.

## Usage

### Static Hugo Website (Recommended)

The static Hugo website provides the same drug combination visualization without requiring a running server:

1. **Run data preprocessing** (required before building the Hugo site):
   ```bash
   cd static_preprocessing/
   ./preprocess_modern.sh
   ```

2. **Build and serve the Hugo site**:
   ```bash
   cd ../hugo-site/
   # For development with live reload:
   hugo server
   # Or build static files for deployment:
   hugo
   ```

3. **Access the site**:
   - Development: `http://localhost:1313`
   - Production: Deploy the `public/` folder to any web hosting service

**Important**: You must run the preprocessing script (`preprocess_modern.sh`) before starting Hugo, as it generates the required data files that the Hugo site depends on.

### Pre-requisites
We recommand running the R analysis on a machine with at least 8 Gb of memory.

The following packages must be installed: `dplyr`, `reshape2`, `readr` and `ggplot2`. 

### Processing in R
To understand the processing and analysis steps from raw data, we recommand to follow the commented script `combos_script.R` and execute it line by line.
However, if you just want to obtain all the output files at once (including the necessary files to run the web app),
you can run the full script with
```
   Rscript combos_script.R
```
on the command line. It should take between 5 and 10 minutes to run. 

### Running the legacy web application (Node.js server)

**Note**: This is the original dynamic web application. For most use cases, the static Hugo website (above) is recommended.

* Run `combos_script.R` (see above) to produce the summarized data files that are used for the web visualization.
* Install [npm](https://docs.npmjs.com/getting-started/installing-node), since the web app is running on Node.js,
a lightweight web server written in javascript. 
* From the directory `combo_web`, run `npm install` (you might need `sudo npm install`, on ubuntu for instance). 
* Run `node server.js`
* In a web browser, go to `http://localhost:3000/combo_app.html`

### Running with Docker
For convenience, a docker image is available on dockerhub.org, and the current web application can be started with the following command:
```
    docker run --rm -p 3000:3000 -d arnaudmgh/synergy-screen-app
```
The Dockerfile is available in this repository.

### Running with Docker on AWS
Additionally, the script aws-init.sh can be used as User Data to start an AWS instance (from a standard Amazon AMI) to host the web application in a private AWS cloud. 
* The security group should allow TCP port 3000 inbound from anywhere;
* The web application will be accessible at `http://<your-instance-IP>:3000/combo_app.html`

### Troubleshooting
* `node server.js` returns `Error: ENOENT: no such file or directory, open './combo_all_combos2.csv'`. Have you run the R script `combos_script.R`, and did it write the file `combo_all_combos2.csv` in the right directory (`combo_web`)?
* The script does not finish: It could be that your machine does not have enough memory. We recommend at least 8 Gb of memory.
