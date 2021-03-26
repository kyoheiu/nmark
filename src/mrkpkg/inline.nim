import re, lists
import def

let
  codespan = re"(`)([^`]*)(`)"
  emphasis = re"(\*)(\S+)([^\*]*)(\S)(\*)"

type
  InlineType* = enum
    link,
    em,
    strong,
    code,
    image,
  
  InlineKind* = enum
    text,
    marker
  
  Inline* = ref InlineObj
  InlineObj = object
    case kind: InlineKind
    of text:
      value: string
    of marker:
      inlineType: InlineType
      number: int

  DelimPotential = enum
    opener,
    closer,
    both

  DelimStack = ref DelimObj
  DelimObj = object
    position: int
    typeDelim: string
    numDelim: int
    isActive: bool
    potential: DelimPotential

  InlineFlag = ref IFObj
  IFObj = object
    isAfterBacktick: bool
    numBacktick: int
    isAfterEmphaAste: bool
    numEmphaAste: int

proc newInlineFlag*(): InlineFlag =
  InlineFlag(
    isAfterBacktick: false,
    numBacktick: 0,
    isAfterEmphaAste: false,
    numEmphaAste: 0
  )

proc parseInline*(line: string): string =
  line.replacef(codespan, "<code>$2</code>")
  .replacef(emphasis, "<em>$2$3$4</em>")

proc newInlineText(s: string): Inline =
  return Inline(kind: text, value: s)

proc newCodeSpan(num: int): Inline =
  return Inline(kind: marker, inlineType: code, number: num)

proc parseInline2*(s: string): seq[Inline] =

  var resultInline: seq[Inline]
  var tempStr: string
  var flag = newInlineFlag()

  for c in s:
    case c

    of '`':
      if tempStr != "":
        result.add(newInlineText(tempStr))
        tempStr = ""
      flag.isAfterBacktick = true
      flag.numBacktick.inc

    else:
      if flag.isAfterBacktick:
        result.add(newCodeSpan(flag.numBacktick))
        flag.isAfterBacktick = false
        flag.numBacktick = 0
      tempStr.add(c)
  
  if flag.isAfterBacktick:
    result.add(newCodeSpan(flag.numBacktick))

  return resultInline