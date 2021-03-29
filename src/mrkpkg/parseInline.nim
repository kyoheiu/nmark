import readInline

type
  ParseFlag = ref PObj
  PObj = object
    positionOpener: int
    positionOpenerInString: int
    positionCloserInString: int
    canMakeAutoLink: bool

proc newParseFlag(): ParseFlag =
  ParseFlag(
    positionOpener: -1,
    positionOpenerInString: -1, 
    positionCloserInString: -1,
    canMakeAutoLink: false
  )

proc parseAutoLink*(delimSeq: var seq[DelimStack]): seq[DelimStack] =

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
        delimSeq[flag.positionOpener].potential = opener
        element.potential = closer
        flag.positionCloserInString = element.position

        autoLinkPositions.add((flag.positionOpenerInString, flag.positionCloserInString))

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