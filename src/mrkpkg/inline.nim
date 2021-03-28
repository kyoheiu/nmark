import lists, json, strutils
import def

type
  InlineType* = enum
    autoLink,
    link,
    em,
    strong,
    code,
    codeBegins,
    codePotentialBegins,
    codeEnds,
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

proc newInlineText(s: string): Inline =
  return Inline(kind: text, value: s)

proc newCodeSpan(num: int): Inline =
  return Inline(kind: marker, inlineType: code, number: num)

proc echoSeqInline*(inlines: seq[Inline]) =
  var s: seq[JsonNode]
  for b in inlines:
    s.add(%b)
  echo s

proc parseInline*(line: string): string =

  var resultInline: seq[Inline]
  var tempStr: string
  var flag = newInlineFlag()

  for c in line:
    case c

    of '`':
      if tempStr != "":
        resultInline.add(newInlineText(tempStr))
        tempStr = ""
      flag.isAfterBacktick = true
      flag.numBacktick.inc

    else:
      if flag.isAfterBacktick:
        resultInline.add(newCodeSpan(flag.numBacktick))
        flag.isAfterBacktick = false
        flag.numBacktick = 0
      tempStr.add(c)
  
  if flag.isAfterBacktick:
    resultInline.add(newCodeSpan(flag.numBacktick))
  elif tempStr != "":
    resultInline.add(newInlineText(tempStr))
  
  var isActiveCode = false
  var numBacktick = 0
  var positionCodeBegins: int

  for i, element in resultInline:
    if element.kind == marker and element.inlineType == code:
      if isActiveCode == false:
        isActiveCode = true
        element.inlineType = codePotentialBegins
        numBacktick = element.number
        positionCodeBegins = i
      elif isActiveCode == true and element.number != numBacktick:
        continue
      else:
        isActiveCode = false
        element.inlineType = codeEnds
        resultInline[positionCodeBegins].inlineType = codeBegins
        numBacktick = 0

    else:
      continue  

  #echoSeqObj resultInline

  var resultText: string
  for element in resultInline:
    if element.kind == text:
      resultText.add(element.value)
    elif element.inlineType == codeBegins:
      resultText.add("<code>")
    elif element.inlineType == codeEnds:
      resultText.add("</code>")
    elif element.inlineType == code or element.inlineType == codePotentialBegins:
      resultText.add(repeat('`', element.number))
  
  return resultText