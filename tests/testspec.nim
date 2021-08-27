import unittest, strutils, json
import ../src/nmark

#type SpecKind = enum
  #tabs
  #backslash
  #entity
  #thematicBreak
  #atxHeading
  #setextHeading
  #indentedCode
  #fencedCode
  #html
  #linkReference
  #paragraph
  #blockQuote
  #listItem
  #lists
  #code
  #emphasis
  #links
  #images
  #autolinks
  #rawHtml
  #otherInline
  #all

proc specTest() =
  let
    f = parseFile("testfiles/spec-test.json")
  var
    begins: int
    ends: int
#    sKind: SpecKind

  echo "Which specification do you want to test?"
  echo """
  1:tabs  2:backslash   3:entity
  4:thematicBreak   5:atxHeading  6:setextHeading
  7:indentedCode  8:fencedCode  9:html
  10:linkReference  11:paragraph  12:blockQuote
  13:listItem 14:lists  15:code
  16:emphasis 17:links  18:images
  19:autolinks  20:rawHtml  21:otherInline
  22:all"""

  var num = readLine(stdin).parseInt

  case num

  of 1:
    begins = 1
    ends = 12
  of 2:
    begins = 12
    ends = 25
  of 3:
    begins = 25
    ends = 42
  of 4:
    begins = 42
    ends = 62
  of 5:
    begins = 62
    ends = 80
  of 6:
    begins = 80
    ends = 107
  of 7:
    begins = 107
    ends = 119
  of 8:
    begins = 119
    ends = 148
  of 9:
    begins = 148
    ends = 192
  of 10:
    begins = 192
    ends = 219
  of 11:
    begins = 219
    ends = 228
  of 12:
    begins = 228
    ends = 253
  of 13:
    begins = 253
    ends = 301
  of 14:
    begins = 301
    ends = 327
  of 15:
    begins = 327
    ends = 350
  of 16:
    begins = 350
    ends = 481
  of 17:
    begins = 481
    ends = 571
  of 18:
    begins = 571
    ends = 593
  of 19:
    begins = 593
    ends = 612
  of 20:
    begins = 612
    ends = 633
  of 21:
    begins = 633
    ends = 653
  of 22:
    begins = 1
    ends = 653
  else:
    echo "This is not right input."
    return

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