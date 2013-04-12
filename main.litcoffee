# Source code

    coLoanDB = new Meteor.Collection("coloan") 

    bookDB = new Meteor.Collection("book") 
    patronDB = new Meteor.Collection("patron") 

    if Meteor.isServer
        coLoanDB._ensureIndex {borrower: 1}

    if Meteor.isServer
        Meteor.methods
            neighbours: (klynge) ->
                graphNeighbours klynge

    objInc = (obj, key) ->
        obj[key] = (obj[key] || 0) + 1

    graphNeighbours = (klynge) ->
        result = {}
        patrons = (bookDB.findOne {_id: klynge}).patrons

        console.log patrons

        for patron in patrons
            books = (patronDB.findOne {_id: patron}).books
            for book in books
                objInc result, book
        result


    if Meteor.isClient
        Meteor.startup ->
            Meteor.call "neighbours", "34647226", (err, result) ->
                console.log result

            w = 900
            h = 400

            force = d3.layout.force()
