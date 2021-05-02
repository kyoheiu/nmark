import unittest, json
import ../src/nmark

type SpecKind = enum
  tabs
  backslash
  entity
  thematicBreak
  atxHeading
  setextHeading
  indentedCode
  fencedCode
  html
  linkReference
  paragraph
  blockQuote
  listItem
  lists
  code
  emphasis
  links
  images
  autolinks
  rawHtml
  otherInline
  all

proc specTest() =
  let
    f = parseFile("testfiles/spec-test.json")
  var
    begins: int
    ends: int
    sKind: SpecKind
  
  sKind = entity

  case sKind

  of tabs:
    begins = 1
    ends = 12
  of backslash:
    begins = 12
    ends = 25
  of entity:
    begins = 25
    ends = 42
  of thematicBreak:
    begins = 42
    ends = 62
  of atxHeading:
    begins = 62
    ends = 80
  of setextHeading:
    begins = 80
    ends = 107
  of indentedCode:
    begins = 107
    ends = 119
  of fencedCode:
    begins = 119
    ends = 148
  of html:
    begins = 148
    ends = 192
  of linkReference:
    begins = 192
    ends = 219
  of paragraph:
    begins = 219
    ends = 228
  of blockQuote:
    begins = 228
    ends = 253
  of listItem:
    begins = 253
    ends = 301
  of lists:
    begins = 301
    ends = 327
  of code:
    begins = 327
    ends = 350
  of emphasis:
    begins = 350
    ends = 481
  of links:
    begins = 481
    ends = 571
  of images:
    begins = 571
    ends = 592
  of autolinks:
    begins = 592
    ends = 612
  of rawHtml:
    begins = 612
    ends = 633
  of otherInline:
    begins = 633
    ends = 653
  of all:
    begins = 1
    ends = 653

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