#python genjoin.py | gzip > book-book.db.z
echo sorting
#zcat book-book.db.z | sort --compress-program=gzip --parallel=`node -e "console.log(require('os').cpus().length>>1)"` | gzip > book-book.db.sorted
zcat book-book.db.z | sort | gzip > book-book.db.sorted.gz
zcat book-book.db.sorted.gz | python handlejoin.py
