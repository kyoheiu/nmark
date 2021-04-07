import json
import nmark

discard """
  action: "run"
"""


let f = parseFile("testfiles/spec-test.json")
var i = 0
for j in f:
  let md = j["markdown"].getStr
  let hl = j["html"].getStr
  let num = j["example"].getInt
  echo num
  if markdown(md) == hl:
    continue
  else:
    i.inc
    echo markdown(md) & hl
    #if i == 5: break
    break