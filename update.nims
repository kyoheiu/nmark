mode = ScriptMode.Verbose

import strutils

const basetext = """
# Perfomance comparison detail

## How to compare
`./casa build` generates 100 same htmls containing a lot of markdown delimiters. Contents and source code are in my [repo](https://github.com/kyoheiu/Casa).

## result
### nim-markdown@0.8.5 >>
"""

# update version number
let nimbleFile = readFile("nmark.nimble")
var version: string
for line in nimbleFile.splitLines:
  if line.startsWith("version"):
    var flag = false
    for c in line:
      if c == '\"' and not flag:
        flag = true
        version.add(c)
      elif flag:
        version.add(c)
      elif c == '\"' and flag:
        flag = false
      else: continue
  else: continue

cd "../casa"

exec("nimble install nmark")
exec("nim c -d:release casa")
exec("hyperfine './casa build' --export-markdown nmark.md")

let nm = readFile("nmark.md")

cd "../casa-clone"

exec("nimble install markdown")
exec("nim c -d:release casa")
exec("hyperfine './casa build' --export-markdown markdown.md")

let ma = readFile("markdown.md")

let s = basetext & ma & """

### nmark@""" & version & """>>
""" & nm

cd "../nmark"

writeFile("perfcmp.md", s)

echo "Done."
