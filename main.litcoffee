# Source code

    bookDB = new Meteor.Collection("book") 
    patronDB = new Meteor.Collection("patron") 
    klyngeDB = new Meteor.Collection("klynge") 
    faustDB = new Meteor.Collection("faust") 

    if Meteor.isServer
        Meteor.methods
            neighbours: (klynge) ->
                graphNeighbours klynge
            lookupTitle: (klynge) ->
                lookupTitle klynge

    lookupTitle = (klynge) ->
        bibdkurl = "http://bibliotek.dk/vis.php?origin=kommando&term1=lid%3D" 
        klyngeDesc =  klyngeDB.findOne klynge
        return klyngeDesc.title if klyngeDesc.title
        faust = klyngeDesc.faust
        html = (Meteor.http.get bibdkurl + faust).content
        re = /<span id="linkSign-item1"[^<]*<.span..nbsp.([^<]*)/
        title = (html.match re)[1]
        klyngeDB.update {_id: klynge}, {"$set": {"title": title}}
        return title

    objInc = (obj, key) ->
        obj[key] = (obj[key] || 0) + 1

    graphNeighbours = (klynge) ->
        result = {}
        for patron in (bookDB.findOne {_id: klynge}).patrons
            for book in (patronDB.findOne {_id: patron}).books
                objInc result, book
        result


    if Meteor.isClient
        Meteor.startup ->
            Meteor.call "neighbours", "34647226", (err, result) ->
                0
                # console.log result 
                #for klynge of result
                #    Meteor.call "lookupTitle", klynge, (err, result) ->

            Meteor.call "lookupTitle", "34647226", (err, result) ->
                console.log result

            nodes = [{name: "a a"}, {name: "b"}, {name: "c"}, {name: "d"}]
            links = [
                {source: 0, target: 1, weight: 1}
                {source: 1, target: 2, weight: 1}
                {source: 2, target: 3, weight: 1}
                {source: 3, target: 1, weight: 1}
                ]
            drawGraph nodes, links

    drawGraph = (nodes, links) ->
            w = window.innerWidth
            h = window.innerHeight

            svg = d3.select("body").append("svg")
            svg.attr("width", w)
            svg.attr("height", h)

            force = d3.layout.force()
            force.charge -120
            force.linkDistance 30
            force.size [w, h]
            force.nodes nodes
            force.links links
            force.start()


            link = svg
                .selectAll(".link")
                .data(links)
                .enter()
                .append("line")
                .attr("class", "link")
                .style("stroke", "#999")
                .style("stroke-width", 1)

            node = svg
                .selectAll(".node")
                .data(nodes)
                .enter()
                .append("text")
                .style("font", "12px sans-serif")
                .style("text-anchor", "middle")
                .style("text-shadow", "1px 1px 0px white, -1px -1px 0px white, 1px -1px 0px white, -1px 1px 0px white")
                .attr("class", "node")
                .call(force.drag)

            force.on "tick", ->
                link.attr("x1", (d) -> d.source.x)
                    .attr("y1", (d) -> d.source.y)
                    .attr("x2", (d) -> d.target.x)
                    .attr("y2", (d) -> d.target.y)

                node
                    .attr("x", (d) -> d.x)
                    .attr("y", (d) -> d.y + 2)
                    .text((d) -> d.name)
