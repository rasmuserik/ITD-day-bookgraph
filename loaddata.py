import pymongo

db = pymongo.Connection(host='127.0.0.1', port=3002).meteor

count = 0
for line in file("uid-bib-_-_-id-lid-klynge-dato-klyngelaan.db"):

    fields = line.split()
    borrower = fields[0]
    faust = fields[5]
    klynge = fields[6]

    db.coloan.insert({"_id": klynge, "borrower": []})
    db.coloan.update({"_id": klynge}, {"$addToSet": {"borrower": borrower}})

    if count % 1000 is 0:
        print count
    count = count + 1
