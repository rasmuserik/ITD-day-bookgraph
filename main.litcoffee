# ![logo](https://solsort.com/_logo.png) BibGraph visualisation

Various visualisation of bibliographic data

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
            if not klynge
                []
            else
                [ (faustDB.find {_id: faust}), (statDB.find {_id: klynge.klynge}) ]


# Source code


## Server commands

    lookupTitle = (klynge) ->
        bibdkurl = "http://bibliotek.dk/vis.php?origin=kommando&term1=lid%3D" 
        klyngeDesc =  klyngeDB.findOne {_id: klynge}
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

    adhl = (klynge) ->
        (adhlDB.findOne {_id: klynge})?.coloans || {}

    if Meteor.isServer
        Meteor.methods
            neighbours: graphNeighbours
            lookupTitle: lookupTitle
            patronKlynger: patronKlynger
            klyngePatrons: klyngePatrons
            adhl: adhl

## Experiments

    if Meteor.isClient
        Meteor.startup ->
            # Vi unge 
            #addGraphNodes "10005802", 15
            # Magasiner/blad
            #addGraphNodes "10006220", 50
            # Film m.m.
            #addGraphNodes "40336644", 25
            # Flunkerne
            addGraphNodes "19037457", 30
            # Silkekejserinden
            # addGraphNodes "35378198", 20

# Traverse/draw graph

    graph = {}

    addGraphNodes = (node, depth) ->
        return undefined if graph[node] isnt undefined
        graph[node] = {_id: node}
        Meteor.call "adhl", node, (err, data) ->
            throw err if err
            children = Object.keys(data).filter (a) -> data[a] > 2
            children.sort (a, b) -> data[b] - data[a]
            graph[node].children = children.slice 1, 10
            children = children.slice 1, depth
            depth = depth * 0.6 | 0
            addGraphNodes(child, depth) for child in children if depth > 2

    if Meteor.isClient then Meteor.startup ->
        setTimeout doDrawGraph, 10000

    doDrawGraph = ->
        nodes = (node for _, node of graph)
        links = []
        for sourceId, source of graph
            if source.children
                for targetId in source.children
                    if graph[targetId]
                        links.push
                            source: source
                            target: graph[targetId]
                
        console.log "doDrawGraph", nodes, links
        force.nodes nodes
        force.links links
        force.gravity(0.01)
        force.start()
        nodes.map updateLabel
        drawGraph(links, nodes)

## Shared graph definitions

    svg = undefined
    force = undefined

## Initialise Graph

    if Meteor.isClient then Meteor.startup ->
        w = window.innerWidth
        h = window.innerHeight
        force = d3.layout.force()
        force.charge -120
        force.linkDistance 200
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

    linebreak = (str, len) ->
        words = str.split /\s/
        lines = []
        line = ""
        for word in words
            if line.length + word.length + 1 < len
                line = line + " " + word
            else
                lines.push line
                line = word
        lines.push line
        result = lines.join " \n"
        result

    updateLabel = (node) ->
        return if node.label isnt undefined
        node.label = ""
        Meteor.call "lookupTitle", node._id, (err, result) ->
            throw err if err 
            node.label = linebreak result, 20

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
