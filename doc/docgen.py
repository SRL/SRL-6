import re
from sys import argv

files = argv[1:]

commentregex = re.compile('\(\*.+?\*\)', re.DOTALL)

for file in files:
    print file
    f = open(file)
    p = file.rfind('/')
    filetrim = file[p+1:]
    p = filetrim.rfind('.simba')
    filetrim2 = filetrim[:p]

    path = 'sphinx/%s.rst' % filetrim2
    o = open(path, 'w+')
    c = ''.join([x for x in f])
    res = commentregex.findall(c)
    for y in res:
        o.write(y[2:][:-2])
    o.close()
    f.close()


