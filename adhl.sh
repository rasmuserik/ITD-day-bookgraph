python genjoin.py > book-book.db
echo sorting
sort --parallel=`node -e "console.log(require('os').cpus().length>>1)"` book-book.db > book-book.db.sorted
python handlejoin.py < book-book.db.sorted
