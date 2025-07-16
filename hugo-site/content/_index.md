---
title: "Drug Combination Synergy Screen"
date: 2025-07-16
draft: false
---

# Links to R code and data

[Link to the code on github (analysis in R and web app in javascript)](https://github.com/arnaudmgh/synergy-screen)

# Visualization of the drug combination data

## Description

This Web App provides visualization for the drug combination screen presented in "Statistical Assessment of Synergy in a Large Replicate-less Drug Combination Screen. Arnaud Amzallag, Sridhar Ramaswamy and Cyril H. Benes."

The screen consists of all the 5788 possible pairs of 108 by 108 drugs, on 40 cell lines, at two concentrations.

There are two ways to plot the viabilities and significant synergies for each cell line: The **drug Pair Checkbox List** and the **Interactive Drug by Drug Heat Map**.

## Drug Pair Checkbox List

You may search for a drug name or a target name with the "find in page" function of your web browser (control+F). To plot the viabilities over the 40 cell lines, check two boxes and press the "Plot Selected Drug Pair" button bellow the list. The viability graph will appear with an explantory title and legend. At the same time, the Drug Pair is selected in the Drug Drug Heat Map (below the viability graph), indicated by a green square, so you can compare the drug pair score with the other drug pairs, in a visual way.

<form id="dlist">
</form>
<button onclick="dcheck()">Plot Selected Drug Pair</button>

<a name="c1"></a>
<div id="pcombo" style='background:white; text-align:center; font: 14px sans-serif;'></div>

<div id="chart1" style="position: relative;">
    <svg><!--rect width="100%" height="100%" fill="white">-->
    </svg>
</div>
<div id="chart2" style="position: relative;">
    <svg><!--rect width="100%" height="100%" fill="white">-->
    </svg>
</div>

## Interactive Drug by Drug Heatmap

Below, the interactive heat map represents the synergy scores for all the 108 by 108 drug combinations tested in the screen, ordered from the drug with the most synergies to drugs showing the least number of synergies. Each combination was tested at 2 concentrations on 40 melanoma cell lines. By default, the absolute synergy score is plotted in the heat map (i.e. the number of cell lines in which synergy was observed for the given combination).

The heat map below is interactive: if you glide the mouse over the plot, the name of the drugs are plotted. If you click on a data square, details about the combination are plotted about the graph: known targets of the drugs, absolute synergy score and specificity score. Additionally a bar plot appears with the viabilities (for the high dose assay) of the combination over all cell lines tested.

## Choose Variable for the Color Scale

<form>
  <p>
  <i>Don't forget to press the </i><b>Update</b><i> bellow after you make you selection</i><br>
  <input type="radio" name="colors" id="syn" checked>Absolute Synergy Score (number of cell lines where the combination showed significant synergy)<br>
  <input type="radio" name="colors" id="spec">Synergy Specificity Score (Absolute score compared with other combinations involving one of the two drugs)<br>
  <input type="radio" name="colors" id="both">Absolute Score in the upper right triangle and Specificity Score in lower left triangle<br>
</p>
</form>

<button onclick="updateColor()">Update</button>

<svg id="combosquare" width=108 height=108>
  <rect width=1000 height=900 fill="white"/>
</svg>
