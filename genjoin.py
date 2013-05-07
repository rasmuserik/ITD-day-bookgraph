import pymongo
import sys

db = pymongo.Connection(host='127.0.0.1', port=3002).meteor

i = 0
maxLen = 0
avgLen = 0

for patron in db.patron.find():
    books = patron["books"][0:500]
    if len(books) > 1 and len(books) < 500:
        for book1 in books:
            for book2 in books:
                print "%s %s" % (book1, book2)
    if i % 1000 is 0:
        print >> sys.stderr, str(i) + "\t" + str(len(books)) + "\t" + str(maxLen) + "\t" + str(avgLen / 1000.0)
        maxLen = 0
        avgLen = 0
    i = i + 1
    maxLen = max(maxLen, len(books))
    avgLen = avgLen + len(books)
