import pymongo

db = pymongo.Connection(host='127.0.0.1', port=3002).meteor

for adhl in db.adhl.find():
    coloans = [[int(key), adhl["coloans"][key]] for key in adhl["coloans"]]
    coloans.sort(key=lambda x: x[1], reverse=True)
    print coloans[0:32]
