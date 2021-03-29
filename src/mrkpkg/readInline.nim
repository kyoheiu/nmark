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

  DelimPotential* = enum
    canOpen,
    canClose,
    both,
    opener,
    closer

  DelimStack* = ref DelimObj
  DelimObj = object
    position*: int
    typeDelim*: string
    numDelim: int
    isActive*: bool
    potential*: DelimPotential

  InlineFlag = ref IFObj
  IFObj = object
    position: int
    isAfterB: bool
    isAfterW: bool
    isAfterP: bool
    isAfterA: bool
    isAfterE: bool
    isAfterX: bool
    number: int

proc newInlineFlag(): InlineFlag =
  InlineFlag(
    position: -1,
    isAfterB: false,
    isAfterW: false,
    isAfterP: false,
    isAfterA: false,
    isAfterE: false,
    isAfterX: false,
    number: 0
  )

proc readAutoLink*(line: string): seq[DelimStack] =

  var resultSeq: seq[DelimStack]

  for i, c in line:
    case c

    of '<':
      resultSeq.add(DelimStack(position: i, typeDelim: "<", numDelim: 1, isActive: true, potential: canOpen))

    of '>':
      resultSeq.add(DelimStack(position: i, typeDelim: ">", numDelim: 1, isActive: true, potential: canClose))

    else:
      continue
  
  return resultSeq



proc readLinkOrImage*(line: string): seq[DelimStack] =

  var resultSeq: seq[DelimStack]
  var flag = newInlineFlag()

  for i, c in line:
    case c

    of '!':
      flag.isAfterX = true

    of '[':
      if flag.isAfterX:
        flag.isAfterX = false
        resultSeq.add(DelimStack(position: i, typeDelim: "![", numDelim: 1, isActive: true, potential: canOpen))
      else:
        resultSeq.add(DelimStack(position: i, typeDelim: "[", numDelim: 1, isActive: true, potential: canOpen))

    of ']':
      resultSeq.add(DelimStack(position: i, typeDelim: "]", numDelim: 1, isActive: true, potential: canClose))

    else:
      continue
  
  return resultSeq



proc readEmphasisAste*(line: string): seq[DelimStack] =
  var resultSeq: seq[DelimStack]
  var flag = newInlineFlag()

  let str = " " & line
  
  for i, c in str:

    if c == ' ':
      if (flag.isAfterE or flag.isAfterP) and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: canClose))
        flag = newInlineFlag()
        flag.isAfterW = true

      else:
        flag = newInlineFlag()
        flag.isAfterW = true
    
    elif puncChar.contains(c):
      if flag.isAfterW and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: canOpen))
        flag = newInlineFlag()
        flag.isAfterP = true

      elif flag.isAfterE and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: canClose))
        flag = newInlineFlag()
        flag.isAfterP = true

      elif flag.isAfterP and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: both))
        flag = newInlineFlag()
        flag.isAfterP = true

    elif c == '*':
      flag.isAfterA = true
      flag.position = i-1
      flag.number.inc
    
    else:
      if flag.isAfterW and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: canOpen))
      elif flag.isAfterE and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: both))
      elif flag.isAfterP and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: canClose))
      flag = newInlineFlag()
      flag.isAfterE = true

  if flag.isAfterE and flag.isAfterA:
    resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: canClose))
  elif flag.isAfterP and flag.isAfterA:
    resultSeq.add(DelimStack(position: flag.position, typeDelim: "*", numDelim: flag.number, isActive: true, potential: canClose))

  return resultSeq



proc readEmphasisUnder*(line: string): seq[DelimStack] =
  var resultSeq: seq[DelimStack]
  var flag = newInlineFlag()

  let str = " " & line
  
  for i, c in str:

    if c == ' ':
      if (flag.isAfterE or flag.isAfterP) and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: canClose))
        flag = newInlineFlag()
        flag.isAfterW = true

      else:
        flag = newInlineFlag()
        flag.isAfterW = true
    
    elif puncChar.contains(c):
      if flag.isAfterW and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: canOpen))
        flag = newInlineFlag()
        flag.isAfterP = true

      elif flag.isAfterE and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: canClose))
        flag = newInlineFlag()
        flag.isAfterP = true

      elif flag.isAfterP and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: both))
        flag = newInlineFlag()
        flag.isAfterP = true

    elif c == '_':
      flag.isAfterA = true
      flag.position = i-1
      flag.number.inc
    
    else:
      if flag.isAfterW and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: canOpen))
      elif flag.isAfterE and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: both))
      elif flag.isAfterP and flag.isAfterA:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: canClose))
      flag = newInlineFlag()
      flag.isAfterE = true

  if flag.isAfterE and flag.isAfterA:
    resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: canClose))
  elif flag.isAfterP and flag.isAfterA:
    resultSeq.add(DelimStack(position: flag.position, typeDelim: "_", numDelim: flag.number, isActive: true, potential: canClose))

  return resultSeq



proc readCodeSpan*(line: string): seq[DelimStack] =

  var resultSeq: seq[DelimStack]
  var flag = newInlineFlag()

  for i, c in line:
    case c

    of '`':
      flag.isAfterB = true
      flag.number.inc
      flag.position = i

    else:
      if flag.isAfterB:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: "`", numDelim: flag.number, isActive: true, potential: both))
        flag.position = 0
        flag.number = 0
        flag.isAfterB = false
  
  if flag.isAfterB:
      resultSeq.add(DelimStack(position: flag.position, typeDelim: "`", numDelim: flag.number, isActive: true, potential: both))
  
  return resultSeq



proc readHardBreak*(line: string): seq[DelimStack] =

  var resultSeq: seq[DelimStack]
  var flag = newInlineFlag()

  for i, c in line:
    case c

    of ' ':
      if flag.isAfterW:
        flag.number.inc
      else:
        flag.isAfterW = true
        flag.position = i
        flag.number.inc

    else:
      if flag.number >= 2:
        resultSeq.add(DelimStack(position: flag.position, typeDelim: " ", numDelim: flag.number, isActive: true, potential: both))
      flag = newInlineFlag()
  
  return resultSeq