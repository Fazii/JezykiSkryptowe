#!/usr/bin/python

import codecs
import re
import os
import datetime
import HTML
import sys
import hashlib
import signal
import time
from glob import glob


class Timeout():
    """Timeout class using ALARM signal."""

    class Timeout(Exception):
        pass

    def __init__(self, sec):
        self.sec = sec

    def __enter__(self):
        signal.signal(signal.SIGALRM, self.raise_timeout)
        signal.alarm(self.sec)

    def __exit__(self, *args):
        signal.alarm(0)

    def raise_timeout(self, *args):
        raise Timeout.Timeout()


if len(sys.argv)<2 or str(sys.argv[1]) == "-h" or str(sys.argv[1]) == "--help":
    print "To jest skrypt pomocniczy, ktory nie powinien byc wywolywany osobno, wywolaj: generator.pl -h aby otrzymac wiecej informacji"
    exit()

endWith = ""
serwer = ""
if len(sys.argv) == 3:
    if sys.argv[2] == "-s":
        serwer = "-s"
    else:
        endWith = str(sys.argv[2])

if len(sys.argv) == 4:
    endWith = str(sys.argv[2])
    serwer = "-s"

path = sys.argv[1]
pathhtml = path + "/output.html"

print path

try:
    f = codecs.open(pathhtml, 'r')
    fe = f.read()
except IOError:
    print "Nieprawidlowa sciezka do pliku zrodlowego"
    exit()

print "\nGenerowanie statystyki\n"
fileList = re.findall('<a href="?\'?([^"\'>]*)', fe)

t = HTML.Table(header_row=['Index', 'File name', 'Size(in bytes)', 'Time of last access', 'Time of last modification',
                           'Time of last metadata change'])
k = 0

maxsize = 0
maxsize_file = ''

atimetime = sys.maxint
atimetime_file = ''

mtimetime = sys.maxint
mtimetime_file = ''

ctimetime = sys.maxint
ctimetime_file = ''
for file in fileList:
    try:
        statinfo = os.stat(file)
    except OSError:
        print "Nie moge uzyskac informacji o: " + file
        continue

    size = statinfo.st_size
    if maxsize < size:
        maxsize = size
        maxsize_file = file

    atime = statinfo.st_atime

    if atimetime > atime:
        atimetime = atime
        atimetime_file = file
    access = datetime.datetime.fromtimestamp(
        int(atime)
    ).strftime('%Y-%m-%d %H:%M:%S')

    mtime = statinfo.st_mtime
    if mtimetime > mtime:
        mtimetime = mtime
        mtimetime_file = file

    modification = datetime.datetime.fromtimestamp(
        int(mtime)
    ).strftime('%Y-%m-%d %H:%M:%S')

    ctime = statinfo.st_ctime
    if ctimetime > ctime:
        ctimetime = ctime
        ctimetime_file = file

    metadata = datetime.datetime.fromtimestamp(
        int(ctime)
    ).strftime('%Y-%m-%d %H:%M:%S')

    k += 1
    t.rows.append([k, file, size, access, modification, metadata])


k = HTML.Table(header_row=['Index', 'Duplicate1', 'Duplicate2'])


def chunk_reader(fobj, chunk_size=1024):
    while True:
        chunk = fobj.read(chunk_size)
        if not chunk:
            return
        yield chunk


def check_for_duplicates(paths, hash=hashlib.sha1):
    hashes = {}
    i = 0
    for path in paths:
        for dirpath, dirnames, filenames in os.walk(path):
            for filename in filenames:
                full_path = os.path.join(dirpath, filename)
                hashobj = hash()
                try:
                    with Timeout(1):
                        for chunk in chunk_reader(open(full_path, 'rb')):
                            hashobj.update(chunk)
                except:
                    print "Nie moge porownac zawartosci pliku " + full_path + " w celu znalezienie duplikatu"
                    continue
                file_id = (hashobj.digest(), os.path.getsize(full_path))
                duplicate = hashes.get(file_id, None)
                if duplicate and full_path.endswith(endWith):
                    i += 1
                    k.rows.append([i, full_path, duplicate])
                else:
                    hashes[file_id] = full_path

check_for_duplicates({path})

htmlcode = str(fe) + str(t) + '<br>' + str(k)
f = codecs.open(pathhtml, 'w')
f.write(htmlcode)

scriptpath = (os.path.dirname(os.path.realpath(__file__)))

if serwer == "-s":
    path = "bash " + scriptpath + "/serwer.sh " + path
    os.system(path)
