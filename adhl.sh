python genjoin.py > book-book.db
sort --parallel=`cat /proc/cpuinfo | grep processor | wc -l` book-book.db > book-book.db.sorted
python handlejoin.py < book-book.db.sorted
