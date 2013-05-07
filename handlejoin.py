import fileinput
import pymongo
db = pymongo.Connection(host='127.0.0.1', port=3002).meteor


books = {}

def similarBook(book):
    books[book] = books.get(book, 0) + 1

def bookDone(current):
    global books
    if current is "":
        return
    result = {}
    for key, val in books.items():
        if val > 1:
            result[key] = val
    if len(result.items()) > 0:
        db.adhl.update({"_id": current}, {"_id": current, "coloans": result}, upsert=True)
    books = {}


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
