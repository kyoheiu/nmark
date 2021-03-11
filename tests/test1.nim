# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest, mrk

test "test1":
  check testProc("testfiles/2.md") == """
<p>This is a test-file.</p>
<h1>heading</h1>
<h2>heading 2</h2>
<p>Nim is a programing language.</p>
<h3>heading 3</h3>
<p>This is a markdown-parser.</p>
<h4>heading 4</h4>
<p>Hello, World!</p>
"""
