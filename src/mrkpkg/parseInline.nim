import re, algorithm, sequtils
import readInline

let
  reAutoLink = re"^[a-zA-Z][a-zA-Z0-9\+\.-]{1,31}:[^\s<>]$"
  reMailLink = re"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
  reLinkDest = re"^\([^\(\)\[\]]*\)"

type
  ParseFlag = ref PObj
  PObj = object
    positionOpener: int
    positionOpenerInString: int
    canMakeAutoLink: bool
    canMakeCode: bool
    number: int
    inactivateLink: bool

proc newParseFlag(): ParseFlag =
  ParseFlag(
    positionOpener: -1,
    positionOpenerInString: -1, 
    canMakeAutoLink: false,
    canMakeCode: false,
    number: -1,
    inactivateLink: false
  )

proc parseAutoLink*(delimSeq: var seq[DelimStack], line: string): seq[DelimStack] =

  var flag = newParseFlag()
  var autoLinkPositions: seq[tuple[begins: int, ends: int]]

  for i, element in delimSeq:

    if element.typeDelim == "<":
      if flag.canMakeAutoLink:
        flag.positionOpener = i
        flag.positionOpenerInString = element.position
      else:
        flag.canMakeAutoLink = true
        flag.positionOpener = i
        flag.positionOpenerInString = element.position

    elif element.typeDelim == ">":
      if flag.canMakeAutoLink:
        let str = line[flag.positionOpenerInString+1 .. element.position-1]
        if str.match(reAutoLink) or str.match(reMailLink):
          delimSeq[flag.positionOpener].potential = opener
          delimSeq[flag.positionOpener].isActive = false
          element.potential = closer
          element.isActive = false

          autoLinkPositions.add((flag.positionOpenerInString, element.position))

          flag = newParseFlag()
      else:
        continue
    
    else:
      continue

  for autoLinkPosition in autoLinkPositions:
    for element in delimSeq:
      if element.position > autoLinkPosition.begins and element.position < autoLinkPosition.ends: 
        element.isActive = false

  return delimSeq



proc parseCodeSpan*(delimSeq: seq[DelimStack]): seq[DelimStack] =

  var flag = newParseFlag()
  var codePositions: seq[tuple[begins: int, ends: int]]

  for i, element in delimSeq:

    if element.typeDelim == "`" and element.isActive:
      if flag.canMakeCode:
        if flag.number == element.numDelim:
          delimSeq[flag.positionOpener].potential = opener
          delimSeq[flag.positionOpener].isActive = false
          element.potential = closer
          element.isActive = false

          codePositions.add((flag.positionOpenerInString, element.position))

          flag = newParseFlag()

        else:
          continue

      else:
        flag.canMakeCode = true
        flag.positionOpener = i
        flag.positionOpenerInString = element.position
        flag.number = element.numDelim
    
    else:
      continue

  for codePosition in codePositions:
    for element in delimSeq:
      if element.position > codePosition.begins and element.position < codePosition.ends: 
        element.isActive = false

  return delimSeq



proc parseLink*(delimSeq: seq[DelimStack], line: string): seq[DelimStack] =

  var flag = newParseFlag()
  var linkPositions: seq[tuple[begins: int, ends: int]]

  for i, element in delimSeq:

    if element.typeDelim == "]" and element.isActive:

      flag.positionOpenerInString = element.position 

      if line[element.position+1 .. ^1].startsWith(reLinkDest):
        
        for j, element in delimSeq.reversed(0, i):

          if flag.inactivateLink:
            if element.typeDelim == "[":
              element.isActive = false
              continue

          elif element.typeDelim == "[" and element.isActive and element.potential == canOpen:
            element.potential = opener
            element.isActive = false

            delimSeq[i].potential = closer
            delimSeq[i].isActive = false

            linkPositions.add((element.position, flag.positionOpenerInString))

            flag.inactivateLink = true

  for linkPosition in linkPositions:
    for element in delimSeq:
      if element.position > linkPosition.begins and element.position < linkPosition.ends: 
        element.isActive = false

  return delimSeq.filter(proc(x: DelimStack): bool = x.isActive)