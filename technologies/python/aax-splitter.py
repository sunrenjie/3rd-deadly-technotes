#!/usr/bin/env python
import os
import re
import subprocess as sp
from subprocess import *
from optparse import OptionParser

# A program that, given an aax file with its activation bytes, outputs commands
# that will decode it into m4a files and split into more m4a files by chapters.
# Stolen from http://stackoverflow.com/questions/30305953/is-there-an-elegant-way-to-split-a-file-by-chapter-using-ffmpeg
# More info about activation bytes is at:
# https://github.com/inAudible-NG/audible-activator


# The chapter info can be parsed without activation bytes.
def parseChapters(filename):
    chapters = []
    command = ["ffmpeg", '-i', filename]
    output = ""
    try:
        # ffmpeg requires an output file and so it errors
        # when it does not get one so we need to capture stderr,
        # not stdout.
        output = sp.check_output(command, stderr=sp.STDOUT, universal_newlines=True)
    except CalledProcessError, e:
        output = e.output

    for line in iter(output.splitlines()):
        m = re.match(r".*Chapter #(\d+:\d+): start (\d+\.\d+), end (\d+\.\d+).*", line)
        num = 0
        if m:
            chapters.append({"name": m.group(1), "start": m.group(2), "end": m.group(3)})
            num += 1
    return chapters


def getChapters():
    parser = OptionParser(usage="usage: %prog [options] filename", version="%prog 1.0")
    parser.add_option("-a", "--activation-bytes", dest="secret", help="Activation Code", metavar="FILE")
    parser.add_option("-i", "--file", dest="infile", help="Input File", metavar="FILE")
    (options, args) = parser.parse_args()
    if not options.infile or not options.secret:
        parser.error('Filename with activation required')
    chapters = parseChapters(options.infile)
    fbase, fext = os.path.splitext(options.infile)
    # while '.m4a' and '.mp4' are basically the same thing, suffix support is much better for the former.
    fext2 = '.m4a'
    infile2 = fbase + fext2
    print("ffmpeg -activation_bytes %s -i %s -vn -c:a copy %s" % (
        options.secret, options.infile, infile2))
    def get_chapter_num_str(chapter):
      # '0:20' => 2; the leading '0:' seems always the same and not very useful.
      assert chapter['name'][0:2] == '0:'
      return chapter['name'].split(':')[-1]
    chap_str_len = len(get_chapter_num_str(chapters[-1]))
    chap_str_format = '%0' + str(chap_str_len) + 'd'
    for chap in chapters:
        n = int(get_chapter_num_str(chap))
        chap['outfile'] = fbase + "-ch-" + chap_str_format % n  + fext2
        chap['origfile'] = infile2
    return chapters


def convertChapters(chapters):
    for chap in chapters:
        # '-to' seems to be treated as '-t'; version: ffmpeg-2.8.6-1.fc23.x86_64
        length = str(float(chap['end']) - float(chap['start']))
        command = [
            "ffmpeg",
            '-ss', chap['start'],
            '-i', chap['origfile'],
            '-t', length,
            '-c:a', 'copy',
            chap['outfile'],
            '#', 'ending at %s' % chap['end']]
        output = ""
        print ' '.join(command)
        continue
        try:
            # ffmpeg requires an output file and so it errors
            # when it does not get one
            output = sp.check_output(command, stderr=sp.STDOUT, universal_newlines=True)
        except CalledProcessError, e:
            output = e.output
            raise RuntimeError("command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))


if __name__ == '__main__':
    chapters = getChapters()
    convertChapters(chapters)
