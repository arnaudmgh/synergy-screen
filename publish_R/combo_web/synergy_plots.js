var w = 1000, h = 250; pad = 70;

var svg1 = d3.select("body").append("svg").attr("id", "scatter")
   .attr("width", w).attr("height", h).attr("border", 1)//.attr("style", "stroke: black")
   svg1.download = "scatter_high_dose";

var svg2 = d3.select("body").append("svg").attr("id", "scatter")
   .attr("width", w).attr("height", h).attr("border", 1)//.attr("style", "stroke: black");
   svg2.download = "scatter_low_dose";

svg1.selectAll("circle").remove();
svg2.selectAll("circle").remove();


function plotit(dose, svgg, myurl) {
  svgg.selectAll("circle").remove();
  svgg.selectAll("line").remove();
  svgg.selectAll("rect").remove();
  svgg.selectAll("g").remove();
  svgg.selectAll("x_axis").remove();
  svgg.selectAll("text").remove();
  //d3.select("#chart1 svg").transition().style("height", 250) //.transition().duration(450)
  //d3.select("#chart2 svg").style("height", 250)
  svgg.transition().style({height: 250 + "px"}).duration(1000)
  //svgg.transition().attr("style", "height 250px").duration(1000)
      d3.csv(myurl, //'http://'+location.hostname+':3001/test.csv', //'http://'+location.hostname+':3000/q?Drug1=CX-4945&Drug2=lenalidomide',
      //d3.csv( "test.csv", //'http://'+location.hostname+':3001/test.csv', //'http://'+location.hostname+':3000/q?Drug1=CX-4945&Drug2=lenalidomide',

          // d3 rows: function to transform the variables of the csv
            function(d) {//console.log(d['est.log.sing1']);
              return {labell: d['cell.line2'], val: +d.viab, conc: d.conc, padj: d.padj, Drug1: d.Drug1, Drug2:d.Drug2,
              sing1: Math.pow(10, -d['est.log.sing1']), 
              sing2: Math.pow(10, -d['est.log.sing2']),
              sing1low: Math.pow(10, -d['est.log.sing1']+1.96*d['sd.log.sing1']),
              sing1high: Math.pow(10, -d['est.log.sing1']-1.96*d['sd.log.sing1']),
              sing2low: Math.pow(10, -d['est.log.sing2']+1.96*d['sd.log.sing2']),
              sing2high: Math.pow(10, -d['est.log.sing2']-1.96*d['sd.log.sing2']),
              comblow: Math.pow(10, Math.log10(+d.viab) - 1.96*d['noise.control.log']),
              combhigh: Math.pow(10, Math.log10(+d.viab) + 1.96*d['noise.control.log']),
              sdexpect: Math.pow(Math.pow(d['sd.log.sing1'], 2) + Math.pow(d['sd.log.sing2'], 2), 1/2)
              }
            }, 
            function(err, dat) {
              if (err) throw err;
              w = parseInt(d3.select("#chart1 svg").style("max-width"));
            

              
            //  ---------------------------------------------------
            //  ------------    SCALES AND AXES    ----------------
            //

              // create scales BEFORE splitting high and low doses
              var xScale = d3.scale.ordinal()
              .domain(dat.map(function(d) { return d.labell; }))
              .rangeRoundBands([pad/2, w-pad/2])

              var yScale = d3.scale.linear()
              //.domain([0, d3.max(dat, function(d) { return d.val; })])
              .domain([0, 1.3])
              .range([h-pad, pad/3])

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
                  .orient("bottom")
                  //.innerTickSize(-h);
                  
              svgg.append("g")
                    .attr("class", "x_axis")
                    .attr("transform", "translate(" + 0 + "," + (h - pad) + ")")
                    .call(xAxis);

              svgg.select(".x_axis")
                    .selectAll("text")
                    //.attr("dy", ".71em")
                    .attr("transform", "translate(-24, 10) rotate(-90)") //   
                    .style("text-anchor", "end")
                    .style("font","11px sans-serif");
                    //.style("font-size","11px");

              } else {
                  var legendRectH = 6;
                  var legendRectW = 10;
                  var legendSpacing = 4;                  
                  var lege = [["#3377FF", dat[0].Drug1], ["green", dat[0].Drug2],
                  ["red", "Combination (Observed)"], ["black", "Combination (Expected if Bliss independent drugs)"]]
                  var legend = svgg.selectAll('.legend')
                    .data(lege)
                    .enter()
                    .append('g')
                    .attr('class', 'legend')
                    .attr('transform', function(d, i) {
                      var height = legendRectH + legendSpacing;
                      var offset =  0 //height //* lege.length / 2;
                      var horz = -2 * legendRectW + pad ;
                      var vert = i * height - offset + h - 0.75*pad;
                      return 'translate(' + (horz) + ',' + (vert) + ')';
                    });

                    legend.append('rect')
                      .attr('width', legendRectW)
                      .attr('height', legendRectH)
                      .style('fill', function(d) {return d[0]})
                      //.style('stroke', color);

                    legend.append('text')
                        .attr('x', legendRectW + legendSpacing)
                        .attr('y', legendRectH) // - legendSpacing
                        .text(function(d) { return d[1]; });
                                            




              //   svgg.append("text")
              //   .attr("text-anchor", "middle")  // this makes it easy to centre the text as the transform is applied to the anchor
              //   .attr("transform", "translate("+ (pad) +","+(h-pad/2)+")")  // text is drawn off the screen top left, move down and out and rotate
              //   .text(dat[0].Drug1);

              }


            //   -------------------------------------------
            //  ------------   DATA POINTS   ----------------
            //

              dat = dat.filter(function(d) {return d.conc==dose});

            svgg.append("text")
            .attr("text-anchor", "middle")  // this makes it easy to centre the text as the transform is applied to the anchor
            .attr("transform", "translate("+ (pad/6) +","+(h/2)+")rotate(-90)")  // text is drawn off the screen top left, move down and out and rotate
            .text("Viability ("+ (dat[0].conc == "high" ? "high dose" : "low dose")+")");



              sc=svgg.selectAll("circle")
               .data(dat)
               .enter(); //.transition()

               //sc.transition();

               // GRAY GUIDES WHERE THERE IS DATA
               sc.append("line").
                 attr("y1", pad/3).attr("y2", h-pad).
                 attr("x1", function(d) {return xScale(d.labell);}).attr("x2", function(d) {return xScale(d.labell);}).
                 style("stroke", "#D4D4D4");


               // ACTUAL VIABILITY (RED DOTS)
               sc.append("circle")
               .attr("cx", function(d) {
                    //console.log(xScale(d.labell));
                    return xScale(d.labell);
               })

               .attr("cy", function(d) {
                    return yScale(d.val); //d.viab
               })
               .attr("r", 5)
               .attr("fill", "red")

               sc.append("line").
                 attr("y1", function(d) {return yScale(d.comblow);}).attr("y2", function(d) {return yScale(d.combhigh);}).
                 attr("x1", function(d) {return xScale(d.labell);}).attr("x2", function(d) {return xScale(d.labell);}).
                 style("stroke", "red");

               sc.append("rect")
               .attr("x", function(d) {
                    return xScale(d.labell)-3-2; // shift the rectangle by half its width so that it's centered.

               })
               .attr("y", function(d) {
                    return yScale(d.sing1)-2; 
               })
               .attr("fill", "#3377FF")
               .attr("width", "6").attr("height", "4")

               sc.append("line").
                 attr("y1", function(d) {return yScale(d.sing1low);}).attr("y2", function(d) {return yScale(d.sing1high);}).
                 attr("x1", function(d) {return xScale(d.labell)-2;}).attr("x2", function(d) {return xScale(d.labell)-2;}).
                 style("stroke", "#3377FF");

               sc.append("rect")
               .attr("x", function(d) {
                    return xScale(d.labell)-3-1;

               })
               .attr("y", function(d) {
                    return yScale(d.sing2)-2; //d.viab
               })
               .attr("width", "6").attr("height", "4")
               .attr("fill", "green")

               sc.append("line").
                 attr("y1", function(d) {return yScale(d.sing2low);}).attr("y2", function(d) {return yScale(d.sing2high);}).
                 attr("x1", function(d) {return xScale(d.labell)-1;}).attr("x2", function(d) {return xScale(d.labell)-1;}).
                 style("stroke", "green");


               sc.append("circle")
               .attr("cx", function(d) {
                   return xScale(d.labell)+1;

               })
               .attr("cy", function(d) {
                    // console.log("expect:")
                    // console.log(d.expect)
                    return yScale(d.sing1*d.sing2); //d.viab
               })
               .attr("r", 3)
               .attr("fill", "black")

               sc.append("line").
                 attr("y1", function(d) {return yScale(Math.pow(10, -(-Math.log10(d.sing1*d.sing2) - 1.96*d.sdexpect)));})
                  .attr("y2", function(d) {return yScale(Math.pow(10, -(-Math.log10(d.sing1*d.sing2) + 1.96*d.sdexpect)));}).
                 attr("x1", function(d) {return xScale(d.labell)+1;}).attr("x2", function(d) {return xScale(d.labell)+1;}).
                 style("stroke", "black");


              // sc.append("circle")
              //   .attr("cx", function(d) {
              //     //console.log("text.x="+xScale(d.labell));
              //     //console.log("d.padj="+d.padj);
              //     return xScale(d.labell);})
              //  // .attr("y", function(d) {
              //  //    return yScale(d.val);})
              //  //.attr("cy", +yScale(0))
              //  .attr("cy", +h-pad+5)
              //  .attr("r", 2)
              //  .style("fill", function(d) { return (d.padj < 0.05 ? (d.sing1*d.sing2 > d.val ? "black" : "pink") : "none")})

               sc.append("rect")
                .attr("x", function(d) {
                  //console.log("text.x="+xScale(d.labell));
                  //console.log("d.padj="+d.padj);
                  return xScale(d.labell)-1.5;})
               // .attr("y", function(d) {
               //    return yScale(d.val);})
               //.attr("cy", +yScale(0))
               .attr("y", +h-pad)
               .attr("r", 2)
               .attr("width", 3).attr("height", 6)
               .style("fill", function(d) { return (d.padj < 0.05 ? (d.sing1*d.sing2 > d.val ? "black" : "#FF7777") : "none")})






            }
      )
}
// plotit("high", svg1)
// plotit("low", svg2)

