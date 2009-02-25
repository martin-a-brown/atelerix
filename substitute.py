#! /usr/bin/env python
#
# -- read a configuration file which contains pairings of text
#    to substitute on STDIN to STDOUT
#

import sys
import re
import string

def transform(mapping, text):
  for tag, replacement in mapping.iteritems():
    text = text.replace( tag, replacement )
  return text

if 2 != len( sys.argv ):
  print >>sys.stderr, "usage: ", sys.argv[0], "<substitution_file>"
  sys.exit(1)

# -- subst is a dictionary of key value substitutions
#
subst = dict()
subst['SUBDATA'] = sys.argv[1]

try:
  file = open( sys.argv[1], 'r' )
except:
  sys.exit(1)

comments = re.compile(r'''^(#.*|\s*)$''')

# -- strip comments out of substitution file and then stack
#    replacements as we process the file (replacements earlier
#    in the file are used later in the file)
#
for line in file:
  if comments.match( line ): continue
  parts = line.rstrip().split(' ', 1)
  if 2 == len( parts ):
    k, v = '@' + parts[0] + '@', parts[1]
  else:
    k, v = '@' + parts[0] + '@', ''
  subst[ k.strip() ] = transform( subst, v.strip() )

# -- print and bail!
# import pprint
# pprint.pprint( subst, sys.stderr )
# sys.exit(1)

# -- and filter it!
#
sys.stdout.write( transform( subst, sys.stdin.read() ) )

#
# -- end of file
