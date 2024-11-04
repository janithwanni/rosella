const setup_anchor = function(message) {
    setup_anchor_data = message;
    console.log("in setup anchor", message)

    var data_array = message.data.id.map((_, index) => {
        let obj = {};
        Object.entries(message.data).forEach(([key,value]) => obj[key] = value[index]); 
        return obj;
    }) 

    const x = make_x_scale(data_array, d => d.prec);
    const y = make_y_scale(data_array, d => d.cover);

    colorScale = d3.scaleOrdinal()
        .domain(data_array.map(d => d.cls_color))
        .range([... new Set(data_array.map(d => d.cls_color))])

    // TODO: Move static coding of id into the message object
    const svg = d3.select("#anchor")
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

    svg.selectAll("circle")
        .data(data_array)
        .join("circle")
        .attr("cx", d => x(d.prec))
        .attr("cy", d => y(d.cover))
        .attr("r", pointSize)
        .attr("fill", d => colorScale(d.cls_color))
        .attr("id", d => `anchor-${d.id}`)
        .attr("data-tippy-content", (d,i) => {
            return `
                Precision: ${+d.prec.toFixed(2)},
                Coverage: ${+d.cover.toFixed(2)}
            `;
        })
        .call(c => tippy(c.nodes()))
        .on("mouseenter", (event, data) => {
            if(!clicked) {
                console.log("mouseenter event fired")
                Shiny.setInputValue(`${message.ns}anchor_mouseover`, {event: event, data: data}, {priority: "event"});
            }
        })
}

const pulse_anchor = function(message) {
    console.log("in pulse anchor", message);

    const svg = d3.select("#anchor")
    const target = svg.select(`#anchor-${message.id}`)
    svg.select("#highlight-circle").remove()

    console.log(svg)
    console.log(target)
    
    if(target.empty() != true) {
        svg.append("g")
            .attr("id", "highlight-circle")
            .call(
                g => g.append("g")
                .append("circle")
                .attr("cx", target.attr("cx"))
                .attr("cy", target.attr("cy"))
                .attr("r", pointSize*2)
                .attr("fill", "transparent")
                .attr("stroke", "black")
                .attr("stroke-width", 5)
                .attr("data-tippy-content", target.attr("data-tippy-content"))
                .call(c => tippy(c.nodes()))
                .on("click", (event, data) => {
                    console.log("received click event")
                    clicked = clicked ? false : true;
                    console.log("firing shiny event", `${message.ns}anchor_mouseclick`)
                    Shiny.setInputValue(`${message.ns}anchor_mouseclick`, {event: event, data: {id: message.id}}, {priority: "event"});
                })
                .on("mouseleave", (event, data) => {
                    console.log(clicked)
                    if(!clicked) {
                        console.log("firing mouseleave event from inner circle", clicked)
                        Shiny.setInputValue(`${message.ns}anchor_mouseover`, null, {priority: "event"});
                        Shiny.setInputValue(`${message.ns}anchor_mouseclick`, null, {priority: "event"});
                    }
                })
            )
    }
}

const clear_plots = function(message) {
    console.log("clearing plots", message)
    setup_anchor(setup_anchor_data)
    setup_trajectory(setup_trajectory_data)
    clear_detourr(message.detourr_id)
}

Shiny.addCustomMessageHandler('setup-anchor', setup_anchor)
Shiny.addCustomMessageHandler('pulse-anchor', pulse_anchor)
Shiny.addCustomMessageHandler("clear-plots", clear_plots)