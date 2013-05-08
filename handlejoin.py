import fileinput
import pymongo
db = pymongo.Connection(host='127.0.0.1', port=3002).meteor


books = {}
count = 0
avgKeys = 0
nonZero = 0

db.adhl.remove()

def similarBook(book):
    books[book] = books.get(book, 0) + 1

def bookDone(current):
    global books, avgKeys, count, nonZero
    if current is "":
        return
    result = {}
    for key, val in books.items():
        if val > 1:
            result[key] = val
    if len(result.items()) > 0:
        nonZero = nonZero + 1
        db.adhl.insert({"_id": current, "coloans": result})
    avgKeys = avgKeys + len(result.items())
    books = {}
    if count % 500 is 0:
        print count, avgKeys / 500.0, nonZero / 500.0
        avgKeys = 0
        nonZero = 0
    count = count + 1


prevBook = ""
for line in fileinput.input():
    bookpair = line.split(" ")
    book1 = bookpair[0].strip()
    book2 = bookpair[1].strip()
    if book1 != prevBook:
        bookDone(prevBook)
        prevBook = book1
    similarBook(book2)
bookDone(prevBook)
