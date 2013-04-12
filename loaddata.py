import pymongo

db = pymongo.Connection(host='127.0.0.1', port=3002).meteor

count = 0
for line in file("uid-bib-_-_-id-lid-klynge-dato-klyngelaan.db"):

    fields = line.split()
    patron = fields[0]
    faust = fields[5]
    klynge = fields[6]

    db.book.insert({"_id": klynge, "patrons": []})
    db.book.update({"_id": klynge}, {"$addToSet": {"patrons": patron}})

    db.patron.insert({"_id": patron, "books": []})
    db.patron.update({"_id": patron}, {"$addToSet": {"books": klynge}})

    if count % 1000 is 0:
        print count
    count = count + 1
