import re
import readInline

let
  reAutoLink = re"^[a-zA-Z][a-zA-Z0-9\+\.-]{1,31}:[^\s<>]$"
  reMailLink = re"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"

type
  ParseFlag = ref PObj
  PObj = object
    positionOpener: int
    positionOpenerInString: int
    canMakeAutoLink: bool
    canMakeCode: bool
    number: int

proc newParseFlag(): ParseFlag =
  ParseFlag(
    positionOpener: -1,
    positionOpenerInString: -1, 
    canMakeAutoLink: false,
    canMakeCode: false,
    number: -1
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
          element.potential = closer

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
          element.potential = closer

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