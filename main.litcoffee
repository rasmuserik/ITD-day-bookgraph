# Database 


    bookDB = new Meteor.Collection("book") 
    patronDB = new Meteor.Collection("patron") 
    klyngeDB = new Meteor.Collection("klynge") 
    faustDB = new Meteor.Collection("faust") 
    statDB = new Meteor.Collection("patronstat") 
    adhlDB = new Meteor.Collection("adhl") 

## Publishing

    if Meteor.isServer
        Meteor.publish "faust", (faust) ->
            klynge = faustDB.findOne {_id: faust}
            console.log "subscribe:", klynge
            if not klynge
                []
            else
                [ (faustDB.find {_id: faust}), (statDB.find {_id: klynge.klynge}) ]


# Source code


## Server commands

    lookupTitle = (klynge) ->
        bibdkurl = "http://bibliotek.dk/vis.php?origin=kommando&term1=lid%3D" 
        klyngeDesc =  klyngeDB.findOne {_id: klynge}
        console.log klynge, bibdkurl 
        if not klyngeDesc
            throw "cannot finde klynge " + klynge
        return klyngeDesc.title if klyngeDesc.title
        faust = klyngeDesc.faust
        html = (Meteor.http.get bibdkurl + faust).content
        re = /<span id="linkSign-item1"[^<]*<.span..nbsp.([^<]*)/
        title = (html.match re)[1]
        klyngeDB.update {_id: klynge}, {"$set": {"title": title}}
        title

    objInc = (obj, key) ->
        obj[key] = (obj[key] || 0) + 1

    graphNeighbours = (klynge) ->
        result = {}
        for patron in (bookDB.findOne {_id: klynge}).patrons
            for book in (patronDB.findOne {_id: patron}).books
                objInc result, book
        result

    klyngePatrons = (klynge) ->
        (bookDB.findOne {_id: klynge}, {patrons: true}).patrons

    patronKlynger = (patron) ->
        (patronDB.findOne {_id: patron}, {books: true}).books

    if Meteor.isServer
        Meteor.methods
            neighbours: graphNeighbours
            lookupTitle: lookupTitle
            patronKlynger: patronKlynger
            klyngePatrons: klyngePatrons

## Experiments

    if Meteor.isClient
        Meteor.startup ->
            doGraph "34647226"
    if false
            Meteor.call "klyngePatrons", "34647226", (err, result) ->
                if err
                    throw err
                console.log "patrons", result
                Meteor.call "patronKlynger", result[0], (err, result) ->
                    console.log "klynger", result

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
            setTimeout(->
                    nodes[0].name = "b b"
                    #links.push
                    #    source: 0
                    #    target: 1
                    #    weight: 1
                    #links[0].target = 2
                , 2000)
            # drawGraph nodes, links

# Traverse/draw graph

    doGraph  = (klynge) ->
        graph = {}
        graph[klynge] = {_id: klynge}
        patrons = {}
        doDrawGraph = ->
            nodes = (node for _, node of graph)
            for node in nodes
                node.children = {}
            console.log nodes, graph
            for _, patron of patrons
                for i in [0..patron.length-1] by 1
                    for j in [i..patron.length-1] by 1
                        book1 = patron[i]
                        book2 = patron[j]
                        # console.log patron[i], patron[j], book1, book2
                        if graph[book1] and graph[book2] and book1 isnt book2
                            graph[book1].children[book2] = (graph[book1].children[book2] or 0) + 1
                            graph[book2].children[book1] = (graph[book2].children[book1] or 0) + 1
            for node in nodes
                links = []
                for child of node.children
                    links.push child
                node.links = links

            graphNodes nodes
        Meteor.call "klyngePatrons", klynge, (err, patronlist) ->
            throw err if err
            for patron in patronlist.slice(0, 1)
                console.log "patron:", patron
                Meteor.call "patronKlynger", patron, (err, result) ->
                    console.log err, result
                    throw err if err
                    patrons[patron] = result
                    doDrawGraph()


## Shared graph definitions

    svg = undefined
    force = undefined

## Draw a graph given nodes

    drawGraph = (nodes, links) ->

### SVG setup

            w = window.innerWidth
            h = window.innerHeight

            svg = d3.select("#graph").append("svg")
            svg.attr("width", w)
            svg.attr("height", h)

### Create force graph

            force = d3.layout.force()
            force.charge -120
            force.linkDistance 30
            force.size [w, h]
            force.nodes nodes
            force.links links
            force.start()


### Draw the links and nodes

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

### Update layout

            force.on "tick", ->
                link.attr("x1", (d) -> d.source.x)
                    .attr("y1", (d) -> d.source.y)
                    .attr("x2", (d) -> d.target.x)
                    .attr("y2", (d) -> d.target.y)

                node
                    .attr("x", (d) -> d.x)
                    .attr("y", (d) -> d.y + 2)
                    .text((d) -> d.name)

## Initialise Graph

    if Meteor.isClient then Meteor.startup ->
        w = window.innerWidth
        h = window.innerHeight
        force = d3.layout.force()
        force.charge -120
        force.linkDistance 30
        force.size [w, h]
        force.on "tick", -> updateForce()
        undefined

## Update graph nodes

    updateForce= -> undefined

    drawGraph = (links, nodes)->
        w = window.innerWidth
        h = window.innerHeight
        document.getElementById("graph").innerHTML = ""
        svg = d3.select("#graph").append("svg")
        svg.attr("width", w)
        svg.attr("height", h)

        # svg.selectAll(".link").exit()
        # svg.selectAll(".node").exit()

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

        updateForce = ->
            link.attr("x1", (d) -> d.source.x)
                .attr("y1", (d) -> d.source.y)
                .attr("x2", (d) -> d.target.x)
                .attr("y2", (d) -> d.target.y)

            node
                .attr("x", (d) -> d.x)
                .attr("y", (d) -> d.y + 2)
                .text((d) -> d.label or d._id)

    updateLabel = (node) ->
        return if node.label isnt undefined
        node.label = ""
        console.log node._id, typeof node._id
        Meteor.call "lookupTitle", node._id, (err, result) ->
            throw err if err 
            console.log result, node
            node.label = result

    graphNodes = (nodeList) ->
        nodes = {}
        links = []
        nodes[node._id] = node for node in nodeList

        for _, node of nodes
            for child in node.links
                links.push
                    source: node
                    target: nodes[child]

        force.nodes nodeList
        force.links links
        force.start()
        nodeList.map updateLabel
        drawGraph(links, nodeList)
        console.log("HERE", nodes, links)


## Test/experiment

    if false and Meteor.isClient then Meteor.startup ->
        graph = [
            { _id: "501663", links: ["603244", "26495", "95540"] }
            { _id: "603244", links: ["501663", "95540"] }
            { _id: "26495", links: ["501663", "255722"] }
            { _id: "95540", links: ["603244", "501663"] }
            { _id: "255722", links: ["26495"] }
        ]
        graphNodes graph
        setTimeout (->
            graph.push {_id: "694326", links: ["501663", "255722", "231710"]}
            graph.push {_id: "231710", links: ["694326", "255722"]}
            graphNodes graph
        ), 3000

# patronstat-vis

Only client code

    if Meteor.isClient

##  Definitions

We need a sample faust number for getting started, this will be removed later on, only used for testing when starting coding

        testFausts = ["29243700", "28682417"]

## Create canvas element in ".patronGraph" elements

        updatePatronGraphs = ->

            # TODO: check up on mongo/local sync, - the following line is needed, for the remainder to work???
            faustDB.findOne {_id: testFausts[0]}

Extract elements and data from DOM


            for elem in document.getElementsByClassName "patronGraph"
                faust = elem.dataset.faust

Read the data from the database

                if faust
                    Meteor.subscribe "faust", faust
                klynge = (faustDB.findOne {_id: faust})?.klynge
                if klynge
 
Create canvas

                    elem.innerHTML = "<canvas id=\"canvasFaust#{faust}\" height=150 width=200></canvas>"

Generate statistic object

                    statEntry = statDB.findOne {_id: klynge}
                    stat = {k:[], m:[]}
                    for key, val of statEntry
                        sex = key[0]
                        age = +key.slice(1)
                        if key isnt "_id"
                            stat[sex][age] = val

Draw the statistics

                    renderStat (document.getElementById "canvasFaust" + faust), stat

## Render a graph of the pagron ages

        renderStat = (canvasElem, stat) ->
            ctx = canvasElem.getContext "2d"

Draw scale at the bottom of the graph.

            for x in [5..95] by 5
                ctx.fillRect 2*x, 100, 1, 2

            for x in [10..90] by 10
                w = (ctx.measureText String x).width
                ctx.fillRect 2*x, 100, 1, 5
                ctx.fillText (String x), 2*x-w/2, 114

Find the maximum value for normalising the graph

            max = 0
            for i in stat.m
                max = Math.max(max, +i) if typeof i is "number"
            for i in stat.k
                max = Math.max(max, +i) if typeof i is "number"

            drawBar = (x, height) ->
                barHeight = 100*height/max
                ctx.fillRect x, 100-barHeight, 1, barHeight

            drawBarAge = (age, sex) ->
                if stat[sex][age]
                    ctx.fillStyle = ({"m": "blue", "k": "red"})[sex]
                    drawBar age*2 + ({"m": 0, "k": 1})[sex], stat[sex][age]

            for age in [1..100]
                drawBarAge age, "m"
                drawBarAge age, "k"

## Callback

Update the visualisation on startup, and whenever the page content changes

        Meteor.startup updatePatronGraphs
        Deps.autorun updatePatronGraphs
