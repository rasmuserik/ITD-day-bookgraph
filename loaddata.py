import pymongo

db = pymongo.Connection(host='127.0.0.1', port=3002).meteor

patronmap = {}
nextPatron = 1

count = 0
for line in file("uid-bib-_-_-id-lid-klynge-dato-klyngelaan.db"):

    fields = line.split()
    patron = fields[0]

    if patron not in patronmap:
        patronmap[patron] = str(nextPatron)
        nextPatron = nextPatron + 1
    patron = patronmap[patron]

    faust = fields[5]
    klynge = fields[6]
    sex = fields[2]
    birthYear = int(fields[3][0:4])
    loanYear = int(fields[7][0:4])
    age = loanYear - birthYear

    db.klynge.insert({"_id": klynge, "faust": faust})
    db.faust.insert({"_id": faust, "klynge": klynge})

    db.book.insert({"_id": klynge, "patrons": []})
    db.book.update({"_id": klynge}, {"$addToSet": {"patrons": patron}})

    db.patronstat.update({"_id": klynge}, {"$inc": {sex + str(age): 1}}, upsert=True)

    db.patron.insert({"_id": patron, "books": []})
    db.patron.update({"_id": patron}, {"$addToSet": {"books": klynge}})

    if count % 1000 is 0:
        print count, nextPatron
    count = count + 1
