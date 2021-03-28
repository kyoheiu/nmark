import lists, json, strutils
import def

const puncChar = ['!', '"', '#', '$', '%', '&', '\'', '(', ')', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~']

type
  InlineType* = enum
    autoLink,
    link,
    leftFlanking,
    rightFlanking,
    bothFlanking,
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
    isAfterW: bool
    isAfterP: bool
    isAfterA: bool
    isAfterE: bool
    numAsterisk: int

proc newInlineFlag*(): InlineFlag =
  InlineFlag(
    isAfterBacktick: false,
    numBacktick: 0,
    isAfterW: false,
    isAfterP: false,
    isAfterA: false,
    isAfterE: false,
    numAsterisk: 0
  )

proc newInlineText(s: string): Inline =
  return Inline(kind: text, value: s)

proc newCodeSpan(num: int): Inline =
  return Inline(kind: marker, inlineType: code, number: num)

proc newDelim(delimType: InlineType, num: int): Inline =
  return Inline(kind: marker, inlineType: delimType, number: num)

proc echoSeqInline*(inlines: seq[Inline]) =
  var s: seq[JsonNode]
  for b in inlines:
    s.add(%b)
  echo s

proc insertEmphasis(line: string): seq[Inline] =
  var resultInline: seq[Inline]
  var tempStr: string
  var flag = newInlineFlag()

  var str = " " & line
  
  for c in str:
    echo tempStr

    if c == ' ':
      if (flag.isAfterE or flag.isAfterP) and flag.isAfterA:
        resultInline.add(newInlineText(tempStr))
        tempStr = ""
        resultInline.add(newDelim(rightFlanking, flag.numAsterisk))
        flag.isAfterE = false
        flag.isAfterP = false
        flag.isAfterA = false
        flag.numAsterisk = 0
        tempStr.add(c)
        flag.isAfterW = true
      elif flag.isAfterW and flag.isAfterA:
        tempStr.add(repeat('*', flag.numAsterisk))
        flag.isAfterW = false
        flag.isAfterA = false
        flag.numAsterisk = 0
        tempStr.add(c)
        flag.isAfterW = true
      else:
        tempStr.add(c)
        flag = newInlineFlag()
        flag.isAfterW = true
    
    elif puncChar.contains(c):
      if flag.isAfterW and flag.isAfterA:
        resultInline.add(newInlineText(tempStr))
        tempStr = ""
        resultInline.add(newDelim(leftFlanking, flag.numAsterisk))
        flag.isAfterW = false
        flag.isAfterA = false
        flag.numAsterisk = 0
      elif flag.isAfterE and flag.isAfterA:
        resultInline.add(newInlineText(tempStr))
        tempStr = ""
        resultInline.add(newDelim(rightFlanking, flag.numAsterisk))
        flag.isAfterE = false
        flag.isAfterA = false
        flag.numAsterisk = 0
      elif flag.isAfterP and flag.isAfterA:
        resultInline.add(newInlineText(tempStr))
        tempStr = ""
        resultInline.add(newDelim(bothFlanking, flag.numAsterisk))
        flag.isAfterP = false
        flag.isAfterA = false
        flag.numAsterisk = 0
      tempStr.add(c)
      flag.isAfterP = true

    elif c == '*':
      flag.isAfterA = true
      flag.numAsterisk.inc
    
    else:
      if flag.isAfterW and flag.isAfterA:
        resultInline.add(newInlineText(tempStr))
        resultInline.add(newDelim(leftFlanking, flag.numAsterisk))
        tempStr = $c
        flag.isAfterW = false
        flag.isAfterA = false
      elif flag.isAfterE and flag.isAfterA:
        resultInline.add(newInlineText(tempStr))
        resultInline.add(newDelim(bothFlanking, flag.numAsterisk))
        tempStr = $c
      elif flag.isAfterP and flag.isAfterA:
        resultInline.add(newInlineText(tempStr))
        resultInline.add(newDelim(leftFlanking, flag.numAsterisk))
        tempStr = $c
      else:
        tempStr.add(c)
        flag = newInlineFlag()
      flag.isAfterE = true

  if tempStr != "": resultInline.add(newInlineText(tempStr))

  return resultInline



proc insertCodeSpan(line: string): seq[Inline] =
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
  
  return resultInline

proc parseCodeSpan(resultInline: seq[Inline]): string =
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



proc parseInline*(line: string): string =
  line.insertCodeSpan.parseCodeSpan


proc parseInline2*(line: string): seq[Inline] =
  line.insertCodeSpan.parseCodeSpan.insertEmphasis