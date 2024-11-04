const setup_trajectory = function(message) {
    setup_trajectory_data = message;
    console.log("in setup trajectory", message)

    traj_data = message.data; // to be used in the trajectory animation
    traj_data_array = message.data.id.map((_, index) => {
        let obj = {};
        Object.entries(message.data).forEach(([key,value]) => obj[key] = value[index]); 
        return obj;
    })

    const x = make_x_scale(traj_data_array, d => d.prec);
    const y = make_y_scale(traj_data_array, d => d.cover);
    
    const svg = d3.select("#trajectory")
    svg.selectAll("*").remove()

    make_x_axis(svg, x, "Precision")
    make_y_axis(svg, y, "Coverage")

    svg.append("g")
    .attr("stroke", "currentColor")
    .attr("stroke-opacity", 0.1)
    .call(g => g.append("g")
      .selectAll("line")
      .data(x.ticks())
      .join("line")
        .attr("x1", d => 0.5 + x(d))
        .attr("x2", d => 0.5 + x(d))
        .attr("y1", marginTop)
        .attr("y2", height - marginBottom))
    .call(g => g.append("g")
      .selectAll("line")
      .data(y.ticks())
      .join("line")
        .attr("y1", d => 0.5 + y(d))
        .attr("y2", d => 0.5 + y(d))
        .attr("x1", marginLeft)
        .attr("x2", width - marginRight));
}

const animate_trajectory = function(message) {
    console.log("animate trajectory", message)

    console.log("prep anim data")
    if(traj_data_array == undefined) {
        return(null);
    }
    const anim_data = traj_data_array.filter(x => x.id == message.id & x.game == message.game)

    console.log("made anim_data", anim_data)

    const x = make_x_scale(anim_data, d => d.prec)
    const y = make_y_scale(anim_data, d => d.cover)

    const svg = d3.select("#trajectory")
    const line = d3.line()
        .curve(d3.curveCatmullRom)
        .x(d => x(d.prec))
        .y(d => y(d.cover));
    const l = length(line(anim_data));

    const alphaScale = d3.scaleLinear()
    .domain(d3.extent(anim_data, d => d.epoch)).nice()
    .range([0.4, 1])

    svg.select("#traj_points").remove()
    svg.select("#traj_path").remove()

    svg.select("x-axis")
        .call(g => d3.axisBottom(x))

    svg.select("y-axis")
        .call(g => d3.axisLeft(y))

    svg.append("path")
        .datum(anim_data)
        .attr("id", "traj_path")
        .attr("fill", "none")
        .attr("stroke", "black")
        .attr("stroke-width", 0.5)
        .attr("stroke-linejoin", "round")
        .attr("stroke-linecap", "round")
        .attr("stroke-dasharray", `0,${l}`)
        .attr("d", line)
    .transition()
        .duration(500)
        .ease(d3.easeLinear)
        .attr("stroke-dasharray", `${l},${l}`);

    svg.append("g")
        .attr("fill", "lightgray")
        .attr("stroke", "black")
        .attr("stroke-width", 1)
        .attr("id", "traj_points")
        .selectAll("circle")
        .data(anim_data)
        .join("circle")
        .attr("cx", d => x(d.prec))
        .attr("cy", d => y(d.cover))
        .attr("r", pointSize)
        .attr("stroke-opacity", d => alphaScale(d.epoch))
        .attr("opacity", d => alphaScale(d.epoch))
        .attr("data-tippy-content", (d, i) => {
            return `
                Precision: ${+d.prec.toFixed(2)},
                Coverage: ${+d.cover.toFixed(2)}
            `
        })
        .call(c => tippy(c.nodes()))
        .on("mouseover", (event, data) => {
            Shiny.setInputValue(`${message.ns}traj_mouseover`, {event: event, data: data}, {priority: "event"});
        })
}

Shiny.addCustomMessageHandler('setup-trajectory', setup_trajectory)
Shiny.addCustomMessageHandler('animate-trajectory',animate_trajectory)