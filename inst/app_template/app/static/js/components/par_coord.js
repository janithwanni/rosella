setup_par_coord = function(message) {
  console.log("in setup_par_coord with message", message);
  par_coord_svg_id = message.svg_id;
  const data = message.data.id.map((_, index) => {
    let obj = {};
    Object.entries(message.data).forEach(([key, value]) => obj[key] = value[index]);
    return(obj);
  })
  console.log("prepared par coord data", data)

  const y = new Map(
    Array.from(cols, key => {
      return (
        [
          key,
          d3.scaleLinear(
            d3.extent(data, d => d[key]),
            [height - marginBottom, marginTop]
          )
        ]
      ) 
    })
  );
  
  const x = d3.scalePoint(cols, [marginLeft, width - marginRight]);
  // creates a line generator
  const line = d3.line()
    .defined(([, value]) => value != null)
    .y(([key, value]) => y.get(key)(value))
    .x(([key]) => x(key));
  
  const svg = d3.select(`#${message.svg_id}`)

  svg
    .append("g")
    .attr("fill", "none")
    .selectAll("path")
    .data(data)
    .join("path")
      .attr("d", d => line(d3.cross(cols, [d], (key, d) => [key, d[key]])))
      .attr("id", d => `${par_coord_svg_id}-parcoord-${d.id}`)
      .attr("stroke", d => d.color)
      .attr("stroke-width", parCoordStrokeWidth)
      .attr("stroke-opacity", parCoordStrokeOpacity)
      .attr('pointer-events', 'stroke')
      .attr("data-tippy-content", (d, i) => `id: ${d.id} | (x: ${+d.x.toFixed(2)}, y: ${+d.y.toFixed(2)}, z: ${+d.z.toFixed(2)}])`)
      .call(c => tippy(
          c.nodes(),
          {
            followCursor: true,
            animation: 'shift-away',
            placement: 'left'
          }
      ))
     
  svg.append("g")
      .selectAll("g")
      .data(cols)
      .join("g")
        .attr("transform", d => {console.log(x(d)); return `translate(${x(d)}, 0)`})
        .each(function(d) { d3.select(this).call(d3.axisLeft(y.get(d))); })
        .call(g => g.append("text")
          .attr("x", -marginLeft)
          .attr("y", 10)
          .attr("text-anchor", "start")
          .attr("fill", "currentColor")
          .text(d => d))
        .call(g => g.selectAll("text")
          .clone(true).lower()
          .attr("fill", "none")
          .attr("stroke-width", 5)
          .attr("stroke-linejoin", "round")
          .attr("stroke", "white"));
}

toggle_highlight_path = function(message) {
  console.log("received message in toggle highlight path", message)
  if(message.highlight) {
    console.log("about to highlight", message.id)
    const target = d3.select(`#${par_coord_svg_id}-parcoord-${message.id}`)
    if(target != null) {
      // reset the highlights
      d3.select(`#${par_coord_svg_id}`).selectAll("path")
      .attr("stroke-width", parCoordStrokeWidth)
      .attr("stroke-opacity", parCoordStrokeOpacity)
      .attr("stroke-dasharray", null)
      // highlight the necessary one
      target
        .attr("stroke-width", parCoordStrokeWidth+1)
        .attr("stroke-opacity", 1)
        .attr("stroke-dasharray", "5,5")
    }
  } else {
    console.log("about to reset everything")
    console.log(d3.select(`#${par_coord_svg_id}`).selectAll("path"))
    d3.select(`#${par_coord_svg_id}`).selectAll("path")
      .attr("stroke-width", parCoordStrokeWidth)
      .attr("stroke-opacity", parCoordStrokeOpacity)
      .attr("stroke-dasharray", null)
  }
}
