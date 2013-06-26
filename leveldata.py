import pymongo
import json

db = pymongo.Connection(host='127.0.0.1', port=3002).meteor

for entry in db.faust.find():
    klynge = str(entry["klynge"])
    faust = str(entry["_id"])
    print json.dumps(["faust", faust, klynge])

for adhl in db.adhl.find():
    coloans = [[str(key), adhl["coloans"][key]] for key in adhl["coloans"]]
    coloans.sort(key=lambda x: x[1], reverse=True)
    if len(coloans) > 1:
        print json.dumps(["adhl", str(adhl["_id"]), coloans[0:50]])
