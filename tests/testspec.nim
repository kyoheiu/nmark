import unittest, json
import ../src/nmark



proc specTest() =
  let
    f = parseFile("testfiles/spec-test.json")
  var
    begins = 253
    ends = 301
  for j in f:
    let
      j = f[begins-1]
      md = j["markdown"].getStr
      mdd = md.markdown
      hl = j["html"].getStr
      num = j["example"].getInt
    if markdown(md) != hl:
      echo num
      echo "---\p" & md & "---" 
      echo mdd
    else:
      echo $num & " -> Success"
    begins.inc
    if begins == ends:
      break

test "spec-test":
  specTest()