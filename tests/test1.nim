import unittest, mrk

test "test1":
  check testProc("testfiles/1.md") == """
<p>This is a test-file.</p>
<h1>heading</h1>
<h2>heading 2</h2>
<p>Nim is a programing language.</p>
<h3>heading 3</h3>
<p>This is a markdown-parser.</p>
<h4>heading 4</h4>
<p>Hello, World!</p>
"""
