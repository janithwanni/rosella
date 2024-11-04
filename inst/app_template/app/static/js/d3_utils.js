let length = (path) => d3.create("svg:path").attr("d", path).node().getTotalLength();

const make_x_scale = function(data, x_accessor) {
  const x = d3.scaleLinear()
    .domain(d3.extent(data, x_accessor)).nice()
    .range([marginLeft, width - marginRight]);
  return(x);
}

const make_y_scale = function(data, y_accessor) {
  const y = d3.scaleLinear()
    .domain(d3.extent(data, y_accessor)).nice()
    .range([height - marginBottom, marginTop]);
  return(y)
}

const make_x_axis = function(svg, x_scale, axis_label, id =  "x-axis") {
  svg.append("g")
    .attr("id", id)
    .attr("transform", `translate(0,${height - marginBottom})`)
    .call(d3.axisBottom(x_scale).ticks(width / 80))
    .call(g => g.select(".domain").remove())
    .call(
        g => g.append("text")
            .attr("x", width)
            .attr("y", marginBottom - 4)
            .attr("fill", "currentColor")
            .attr("text-anchor", "end")
            .text(`"${axis_label} →"`)
    )
}

const make_y_axis = function(svg, y_scale, axis_label, id = "y-axis") {
  svg.append("g")
        .attr("id", id)
        .attr("transform", `translate(${marginLeft}, 0)`)
        .call(d3.axisLeft(y_scale))
        .call(g => g.select(".domain").remove())
        .call(
            g => g.append("text")
                .attr("x", -marginLeft)
                .attr("y", 10)
                .attr("fill", "currentColor")
                .attr("text-anchor", "start")
                .text(`↑ ${axis_label}`)
    )
}

const clear_detourr = function(id) {
  var widget = HTMLWidgets.find(`#${id}`);
  if(widget != undefined) {
      var scatter = widget.s;
      scatter.clearPoints();
      scatter.clearEdges();
      scatter.clearHighlight();
      scatter.clearEnlarge();
      scatter.forceRerender();
  }
}