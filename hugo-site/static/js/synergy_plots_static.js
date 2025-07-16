var w = 1000, h = 250; pad = 70;

var svg1 = d3.select("body").append("svg").attr("id", "scatter")
   .attr("width", w).attr("height", h).attr("border", 1);
   svg1.download = "scatter_high_dose";

var svg2 = d3.select("body").append("svg").attr("id", "scatter")
   .attr("width", w).attr("height", h).attr("border", 1);
   svg2.download = "scatter_low_dose";

svg1.selectAll("circle").remove();
svg2.selectAll("circle").remove();

// Modified plotit function to work with pre-parsed data instead of URL
function plotit(dose, svgg, myurl, preloadedData) {
  svgg.selectAll("circle").remove();
  svgg.selectAll("line").remove();
  svgg.selectAll("rect").remove();
  svgg.selectAll("g").remove();
  svgg.selectAll("x_axis").remove();
  svgg.selectAll("text").remove();
  
  svgg.transition().style({height: 250 + "px"}).duration(1000);
  
  // Use preloaded data if available, otherwise fall back to URL loading
  if (preloadedData) {
    processPlotData(preloadedData, dose, svgg);
  } else if (myurl) {
    d3.csv(myurl, transformCSVRow, function(err, dat) {
      if (err) throw err;
      processPlotData(dat, dose, svgg);
    });
  }
}

// Function to transform CSV rows (same as original)
function transformCSVRow(d) {
  return {
    labell: d['cell.line2'], 
    val: +d.viab, 
    conc: d.conc, 
    padj: d.padj, 
    Drug1: d.Drug1, 
    Drug2: d.Drug2,
    sing1: Math.pow(10, -d['est.log.sing1']), 
    sing2: Math.pow(10, -d['est.log.sing2']),
    sing1low: Math.pow(10, -d['est.log.sing1']+1.96*d['sd.log.sing1']),
    sing1high: Math.pow(10, -d['est.log.sing1']-1.96*d['sd.log.sing1']),
    sing2low: Math.pow(10, -d['est.log.sing2']+1.96*d['sd.log.sing2']),
    sing2high: Math.pow(10, -d['est.log.sing2']-1.96*d['sd.log.sing2']),
    comblow: Math.pow(10, Math.log10(+d.viab) - 1.96*d['noise.control.log']),
    combhigh: Math.pow(10, Math.log10(+d.viab) + 1.96*d['noise.control.log']),
    sdexpected: Math.pow(Math.pow(d['sd.log.sing1'], 2) + Math.pow(d['sd.log.sing2'], 2), 1/2)
  };
}

// Main plotting logic extracted into separate function
function processPlotData(dat, dose, svgg) {
  // Transform data if it's raw CSV data
  if (dat.length > 0 && typeof dat[0].val === 'string') {
    dat = dat.map(transformCSVRow);
  }
  
  w = parseInt(d3.select("#chart1 svg").style("max-width"));

  // Create scales BEFORE splitting high and low doses
  var xScale = d3.scale.ordinal()
    .domain(dat.map(function(d) { return d.labell; }))
    .rangeRoundBands([pad/2, w-pad/2]);

  var yScale = d3.scale.linear()
    .domain([0, 1.3])
    .range([h-pad, pad/3]);

  var yAxis = d3.svg.axis()
    .scale(yScale)
    .orient("left")
    .innerTickSize(-w+pad)
    .ticks(3);

  svgg.append("g")
    .attr("class", "y_axis")
    .attr("transform", "translate(" + pad/2 + "," + 0 + ")")
    .call(yAxis);

  if (dose == "low") {
    var xAxis = d3.svg.axis()
      .scale(xScale)
      .orient("bottom");
      
    svgg.append("g")
      .attr("class", "x_axis")
      .attr("transform", "translate(" + 0 + "," + (h - pad) + ")")
      .call(xAxis);

    svgg.select(".x_axis")
      .selectAll("text")
      .attr("transform", "translate(-24, 10) rotate(-90)")
      .style("text-anchor", "end")
      .style("font","11px sans-serif");

  } else {
    var legendRectH = 6;
    var legendRectW = 10;
    var legendSpacing = 4;                  
    var lege = [["#3377FF", dat[0].Drug1], ["green", dat[0].Drug2],
    ["red", "Combination (Observed)"], ["black", "Combination (Expected if Bliss independent drugs)"]];
    
    var legend = svgg.selectAll('.legend')
      .data(lege)
      .enter()
      .append('g')
      .attr('class', 'legend')
      .attr('transform', function(d, i) {
        var height = legendRectH + legendSpacing;
        var offset = 0;
        var horz = -2 * legendRectW + pad;
        var vert = i * height - offset + h - 0.75*pad;
        return 'translate(' + (horz) + ',' + (vert) + ')';
      });

    legend.append('rect')
      .attr('width', legendRectW)
      .attr('height', legendRectH)
      .style('fill', function(d) {return d[0]});

    legend.append('text')
      .attr('x', legendRectW + legendSpacing)
      .attr('y', legendRectH)
      .text(function(d) { return d[1]; });
  }

  // Filter data for the specified dose
  dat = dat.filter(function(d) {return d.conc==dose});

  svgg.append("text")
    .attr("text-anchor", "middle")
    .attr("transform", "translate("+ (pad/6) +","+(h/2)+")rotate(-90)")
    .text("Viability ("+ (dat[0].conc == "high" ? "high dose" : "low dose")+")");

  var sc = svgg.selectAll("circle")
    .data(dat)
    .enter();

  // GRAY GUIDES WHERE THERE IS DATA
  sc.append("line")
    .attr("y1", pad/3).attr("y2", h-pad)
    .attr("x1", function(d) {return xScale(d.labell);})
    .attr("x2", function(d) {return xScale(d.labell);})
    .style("stroke", "#D4D4D4");

  // ACTUAL VIABILITY (RED DOTS)
  sc.append("circle")
    .attr("cx", function(d) { return xScale(d.labell); })
    .attr("cy", function(d) { return yScale(d.val); })
    .attr("r", 5)
    .attr("fill", "red");

  sc.append("line")
    .attr("y1", function(d) {return yScale(d.comblow);})
    .attr("y2", function(d) {return yScale(d.combhigh);})
    .attr("x1", function(d) {return xScale(d.labell);})
    .attr("x2", function(d) {return xScale(d.labell);})
    .style("stroke", "red");

  // Drug 1 rectangles (blue)
  sc.append("rect")
    .attr("x", function(d) { return xScale(d.labell)-3-2; })
    .attr("y", function(d) { return yScale(d.sing1)-2; })
    .attr("fill", "#3377FF")
    .attr("width", "6").attr("height", "4");

  sc.append("line")
    .attr("y1", function(d) {return yScale(d.sing1low);})
    .attr("y2", function(d) {return yScale(d.sing1high);})
    .attr("x1", function(d) {return xScale(d.labell)-2;})
    .attr("x2", function(d) {return xScale(d.labell)-2;})
    .style("stroke", "#3377FF");

  // Drug 2 rectangles (green)
  sc.append("rect")
    .attr("x", function(d) { return xScale(d.labell)-3-1; })
    .attr("y", function(d) { return yScale(d.sing2)-2; })
    .attr("width", "6").attr("height", "4")
    .attr("fill", "green");

  sc.append("line")
    .attr("y1", function(d) {return yScale(d.sing2low);})
    .attr("y2", function(d) {return yScale(d.sing2high);})
    .attr("x1", function(d) {return xScale(d.labell)-1;})
    .attr("x2", function(d) {return xScale(d.labell)-1;})
    .style("stroke", "green");

  // Expected combination (black circles)
  sc.append("circle")
    .attr("cx", function(d) { return xScale(d.labell)+1; })
    .attr("cy", function(d) { return yScale(d.sing1*d.sing2); })
    .attr("r", 3)
    .attr("fill", "black");

  sc.append("line")
    .attr("y1", function(d) {
      return yScale(Math.pow(10, -(-Math.log10(d.sing1*d.sing2) - 1.96*d.sdexpected)));
    })
    .attr("y2", function(d) {
      return yScale(Math.pow(10, -(-Math.log10(d.sing1*d.sing2) + 1.96*d.sdexpected)));
    })
    .attr("x1", function(d) {return xScale(d.labell)+1;})
    .attr("x2", function(d) {return xScale(d.labell)+1;})
    .style("stroke", "black");

  // Significance indicators
  sc.append("rect")
    .attr("x", function(d) { return xScale(d.labell)-1.5; })
    .attr("y", +h-pad)
    .attr("width", 3).attr("height", 6)
    .style("fill", function(d) { 
      return (d.padj < 0.05 ? (d.sing1*d.sing2 > d.val ? "black" : "#FF7777") : "none");
    });
}
