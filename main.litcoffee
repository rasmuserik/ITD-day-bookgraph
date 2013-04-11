# Source code

    coLoanDB = new Meteor.Collection("coloan") 
    coLoanCacheDB = new Meteor.Collection("coloanCache") 

    if Meteor.isServer
        Fiber = Npm.require "fibers" 
        coLoanDB._ensureIndex {borrower: 1}

    if Meteor.isServer
        Meteor.methods
            neighbours: (klynge) ->
                graphNeighbours klynge

    objInc = (obj, key) ->
        obj[key] = (obj[key] || 0) + 1

    graphNeighbours = (klynge) ->
        result = {}
        book = coLoanDB.findOne {_id: klynge}

        for patron in book.borrower
            loans = coLoanDB.find {borrower: patron}, {_id: true, borrower: false}
            loans.fetch().map ((obj) -> objInc result, obj._id)
        result


    if Meteor.isClient
        Meteor.startup ->
            Meteor.call "neighbours", "34647226", (err, result) ->
                console.log result
