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



proc parseLink*(delimSeq: seq[DelimStack], line: string): seq[DelimStack] =

  var flag = newParseFlag()
  var linkPositions: seq[tuple[begins: int, ends: int]]

  for i, element in delimSeq:

    if element.typeDelim == "]" and element.isActive:

      flag.positionOpenerInString = element.position 

      if line[element.position+1 .. ^1].startsWith(reLinkDest):
        
        for j, element in delimSeq[0..i].reversed:

          if flag.inactivateLink:
            if element.typeDelim == "[":
              element.isActive = false
              continue

          elif (element.typeDelim == "[" or element.typeDelim == "![") and element.isActive and element.potential == canOpen:
            element.potential = opener

            delimSeq[i].potential = closer

            linkPositions.add((element.position, flag.positionOpenerInString))

            flag.inactivateLink = true

  if linkPositions.len() != 0:
    for linkPosition in linkPositions:
      for element in delimSeq:
        if element.position > linkPosition.begins and element.position < linkPosition.ends: 
          element.isActive = false

  return delimSeq



proc parseEmphasis*(delimSeq: seq[DelimStack]): seq[DelimStack] =

  var resultDelims: seq[DelimStack]

  for i, closingElement in delimSeq:

    block doubleLoop:

      if closingElement.isActive and (closingElement.potential == canClose or closingElement.potential == both):

        for openingElement in delimSeq[0..i-1].reversed:
          if openingElement.isActive and closingElement.typeDelim == openingElement.typeDelim and (openingElement.potential == canOpen or openingElement.potential == both):

            if closingElement.numDelim >= 2 and openingElement.numDelim >= 2:
              
              resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
              resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

              openingElement.numDelim -= 2
              closingElement.numDelim -= 2
              if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                closingElement.potential = none
                openingElement.potential = none
                break doubleLoop
              elif openingElement.numDelim == 0:
                openingElement.potential = none
                continue
              else:
                closingElement.potential = none
                break doubleLoop

            if openingElement.numDelim >= 2 and closingElement.numDelim == 1:
              
              resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-1, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

              openingElement.numDelim -= 1
              closingElement.potential = none
              break doubleLoop
            
            if openingElement.numDelim == 1 and closingElement.numDelim >= 2:
              
              resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

              openingElement.potential = none
              closingElement.numDelim -= 1
              closingElement.position += 1
              continue
            
            else:
              resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

              openingElement.potential = none
              closingElement.potential = none
              break doubleLoop

    continue

  return resultDelims



proc parseInline*(line: string): seq[DelimStack] =

  var r = (line.readAutoLink & line.readLinkOrImage & line.readCodeSpan & line.readEmphasisAste & line.readEmphasisUnder & line.readHardBreak).sortedByIt(it.position)

  let n_em = r.parseAutoLink(line).parseCodeSpan.parseLink(line).filter(proc(x: DelimStack): bool = (x.typeDelim != "*" and x.typeDelim != "_"))

  let em = r.parseEmphasis

  return (n_em & em).sortedByIt(it.position).filter(proc(x: DelimStack): bool = (x.isActive) and x.potential != both)