from regex import re, match, startsWith
from json import `%`, `$`
from strutils import contains
from algorithm import reversed, sortedByIt
import sequtils
import readInline

let
  reAutoLink = re"^[a-zA-Z][a-zA-Z0-9\+\.-]{1,31}:[^\s<>]*$"
  reMailLink = re"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
  reLinkDest = re"\(.*\)"
  reRawHtmlOpenTag = re"""^[a-zA-Z][a-zA-Z0-9-]*(\s[a-zA-Z_:][a-zA-Z0-9_\.:-]*(\s?=\s?([^\s"'=<>`]+|'[^']*'|"[^"]*"))?)*\s*/?$"""
  reRawHtmlClosingTag = re"^/[a-zA-Z][a-zA-Z0-9\-]*\s?$"
  reRawHtmlComment = re"!--[\s\S]*--"
  reRawHtmlPI = re"\?.+?"
  reRawHtmlDec = re"![A-Z]+\s.+"
  reRawHtmlCDATA = re"!\[CDATA\[.+\]\]"

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

proc echoObj*(s: seq[DelimStack]) =
  debugEcho $(s.map(`%`))

proc parseEscape*(delimSeq: var seq[DelimStack]): var seq[DelimStack] =
  var escapePos = -2
  for i, element in delimSeq:
    if element.position == escapePos+1 and element.typeDelim != "`":
      element.isActive = false
      escapePos = -2
    elif element.typeDelim == "\\" and element.isActive:
      escapePos = element.position
  
  return delimSeq

proc isHtmlComment(line: string): bool =
  let str = line[3..^3]
  if str.contains("--") or
     str[0] == '>' or
     str[0..1] == "->" or
     str[^1] == '-':
    return false
  else: return true

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
        if str.match(reAutoLink):
          delimSeq[flag.positionOpener].potential = linkOpener
          element.potential = closer
          autoLinkPositions.add((flag.positionOpenerInString, element.position))
          flag = newParseFlag()

        elif str.match(reMailLink):
          delimSeq[flag.positionOpener].potential = mailOpener
          element.potential = closer
          autoLinkPositions.add((flag.positionOpenerInString, element.position))
          flag = newParseFlag()
        
        elif str.match(reRawHtmlOpenTag) or
             str.match(reRawHtmlClosingTag) or
             str.match(reRawHtmlPI) or
             str.match(reRawHtmlDec) or
             str.match(reRawHtmlCDATA):
          delimSeq[flag.positionOpener].potential = htmlTag
          element.potential = closer
          autoLinkPositions.add((flag.positionOpenerInString, element.position))
          flag = newParseFlag()
        
        elif str.match(reRawHtmlComment):
          if str.isHtmlComment:
            delimSeq[flag.positionOpener].potential = htmlTag
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

    if element.typeDelim == "`" and element.isActive and
       element.potential == both:
      flag.positionOpener = i
      flag.positionOpenerInString = element.position
      flag.number = element.numDelim
    
      for j, element in delimSeq[i+1..^1]:
        if element.typeDelim == "`" and
           element.isActive and
           element.numDelim == flag.number:
          delimSeq[flag.positionOpener].potential = opener
          element.potential = closer

          codePositions.add((flag.positionOpenerInString, element.position))

          flag = newParseFlag()

          for codePosition in codePositions:
            for element in delimSeq:
              if element.isActive and
                 element.position > codePosition.begins and
                 element.position < codePosition.ends: 
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

          if (element.typeDelim == "[" or element.typeDelim == "![") and
               element.isActive and
               element.potential == canOpen:

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



proc parseEmphasis*(delimSeq: var seq[DelimStack]): seq[DelimStack] =

  var resultDelims: seq[DelimStack]

  delimSeq = delimSeq.filter(proc(x: DelimStack): bool = x.typeDelim == "*" or x.typeDelim == "_")

  for i, closingElement in delimSeq:

    block doubleLoop:

      if closingElement.isActive and closingElement.potential == canClose:

        for j, openingElement in delimSeq[0..i-1].reversed:
          if openingElement.isActive and closingElement.typeDelim == openingElement.typeDelim and openingElement.potential == canOpen:

            while openingElement.numDelim != 0:

              if closingElement.numDelim >= 2 and openingElement.numDelim >= 2:
                
                resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
                resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

                openingElement.numDelim -= 2
                closingElement.numDelim -= 2
                closingElement.position += 2 

                for element in delimSeq:
                  if element.position in (openingElement.position+1..closingElement.position-1):
                    element.isActive = false

                if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                  closingElement.potential = none
                  openingElement.potential = none
                  break doubleLoop
                elif openingElement.numDelim == 0:
                  openingElement.potential = none
                  continue
                elif closingElement.numDelim == 0:
                  closingElement.potential = none
                  break doubleLoop
                else:
                  continue

              elif openingElement.numDelim >= 2 and closingElement.numDelim == 1:
                
                resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-1, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                for element in delimSeq:
                  if element.position in (openingElement.position+1..closingElement.position-1):
                    element.isActive = false

                openingElement.numDelim -= 1
                closingElement.potential = none
                break doubleLoop
              
              elif openingElement.numDelim == 1 and closingElement.numDelim >= 2:
                
                resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                for element in delimSeq:
                  if element.position in (openingElement.position+1..closingElement.position-1):
                    element.isActive = false

                openingElement.potential = none
                closingElement.numDelim -= 1
                closingElement.position += 1
                break
              
              else:
                resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                openingElement.potential = none
                closingElement.potential = none

                for element in delimSeq:
                  if element.position in (openingElement.position+1..closingElement.position-1):
                    element.isActive = false

                break doubleLoop

          elif openingElement.isActive and closingElement.typeDelim == openingElement.typeDelim and openingElement.potential == both:

            let sum = openingElement.numDelim + closingElement.numDelim
            let remOpener = openingElement.numDelim mod 3
            let remCloser = closingElement.numDelim mod 3

            if sum mod 3 == 0:
              if remOpener == 0 and remCloser == 0:

                while openingElement.numDelim != 0:

                  if closingElement.numDelim >= 2 and openingElement.numDelim >= 2:
                    
                    resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
                    resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

                    openingElement.numDelim -= 2
                    closingElement.numDelim -= 2
                    closingElement.position += 2 

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                      closingElement.potential = none
                      openingElement.potential = none
                      break doubleLoop
                    elif openingElement.numDelim == 0:
                      openingElement.potential = none
                      continue
                    elif closingElement.numDelim == 0:
                      closingElement.potential = none
                      break doubleLoop
                    else:
                      continue

                  elif openingElement.numDelim >= 2 and closingElement.numDelim == 1:
                    
                    resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-1, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    openingElement.numDelim -= 1
                    closingElement.potential = none
                    break doubleLoop
                  
                  elif openingElement.numDelim == 1 and closingElement.numDelim >= 2:
                    
                    resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    openingElement.potential = none
                    closingElement.numDelim -= 1
                    closingElement.position += 1
                    continue
                  
                  else:
                    resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    openingElement.potential = none
                    closingElement.potential = none
                    break doubleLoop

              else:

                while openingElement.numDelim >= 2 and closingElement.numDelim >= 2:

                  resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
                  resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.numDelim -= 2
                  closingElement.numDelim -= 2
                  closingElement.position += 2 

                  if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                    closingElement.potential = none
                    openingElement.potential = none
                    break doubleLoop
                  elif openingElement.numDelim == 0:
                    openingElement.potential = none
                    break doubleLoop
                  elif closingElement.numDelim == 0:
                    closingElement.potential = none
                    break doubleLoop
                  else:
                    continue

            else:

              while openingElement.numDelim != 0:

                if closingElement.numDelim >= 2 and openingElement.numDelim >= 2:
                  
                  resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
                  resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

                  openingElement.numDelim -= 2
                  closingElement.numDelim -= 2
                  closingElement.position += 2 

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                    closingElement.potential = none
                    openingElement.potential = none
                    break doubleLoop
                  elif openingElement.numDelim == 0:
                    openingElement.potential = none
                    continue
                  elif closingElement.numDelim == 0:
                    closingElement.potential = none
                    break doubleLoop
                  else:
                    continue

                elif openingElement.numDelim >= 2 and closingElement.numDelim == 1:
                  
                  resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-1, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.numDelim -= 1
                  closingElement.potential = none
                  break doubleLoop
                
                elif openingElement.numDelim == 1 and closingElement.numDelim >= 2:
                  
                  resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.potential = none
                  closingElement.numDelim -= 1
                  closingElement.position += 1
                  continue
                
                else:
                  resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.potential = none
                  closingElement.potential = none
                  break doubleLoop

      elif closingElement.isActive and closingElement.potential == both:

        for openingElement in delimSeq[0..i-1].reversed:

          if openingElement.isActive and closingElement.typeDelim == openingElement.typeDelim and (openingElement.potential == canOpen or openingElement.potential == both):

            let sum = openingElement.numDelim + closingElement.numDelim

            if sum mod 3 == 0:
              let remOpener = openingElement.numDelim mod 3
              let remCloser = closingElement.numDelim mod 3
              if remOpener == 0 and remCloser == 0:

                while openingElement.numDelim != 0:

                  if closingElement.numDelim >= 2 and openingElement.numDelim >= 2:
                    
                    resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
                    resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    openingElement.numDelim -= 2
                    closingElement.numDelim -= 2
                    closingElement.position += 2 

                    if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                      closingElement.potential = none
                      openingElement.potential = none
                      break doubleLoop
                    elif openingElement.numDelim == 0:
                      openingElement.potential = none
                      continue
                    elif closingElement.numDelim == 0:
                      closingElement.potential = none
                      break doubleLoop
                    else:
                      continue

                  elif openingElement.numDelim >= 2 and closingElement.numDelim == 1:
                    
                    resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-1, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    openingElement.numDelim -= 1
                    closingElement.potential = none
                    break doubleLoop
                  
                  elif openingElement.numDelim == 1 and closingElement.numDelim >= 2:
                    
                    resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    openingElement.potential = none
                    closingElement.numDelim -= 1
                    closingElement.position += 1
                    continue
                  
                  else:
                    resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                    for element in delimSeq:
                      if element.position in (openingElement.position+1..closingElement.position-1):
                        element.isActive = false

                    openingElement.potential = none
                    closingElement.potential = none
                    break doubleLoop

              else:

                while openingElement.numDelim >= 2 and closingElement.numDelim >= 2:

                  resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
                  resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.numDelim -= 2
                  closingElement.numDelim -= 2
                  closingElement.position += 2 

                  if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                    closingElement.potential = none
                    openingElement.potential = none
                    break doubleLoop
                  elif openingElement.numDelim == 0:
                    openingElement.potential = none
                    break doubleLoop
                  elif closingElement.numDelim == 0:
                    closingElement.potential = none
                    break doubleLoop
                  else:
                    continue
                
            else:

              while openingElement.numDelim != 0:

                if closingElement.numDelim >= 2 and openingElement.numDelim >= 2:
                  
                  resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-2, typeDelim: "strong", numDelim: 2, isActive: true, potential: opener)])
                  resultDelims.add(@[DelimStack(position: closingElement.position, typeDelim: "strong", numDelim: 2, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.numDelim -= 2
                  closingElement.numDelim -= 2
                  closingElement.position += 2 

                  if closingElement.numDelim == 0 and openingElement.numDelim == 0:
                    closingElement.potential = none
                    openingElement.potential = none
                    break doubleLoop
                  elif openingElement.numDelim == 0:
                    openingElement.potential = none
                    continue
                  elif closingElement.numDelim == 0:
                    closingElement.potential = none
                    break doubleLoop
                  else:
                    continue

                elif openingElement.numDelim >= 2 and closingElement.numDelim == 1:
                  
                  resultDelims.add(@[DelimStack(position: openingElement.position+openingElement.numDelim-1, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.numDelim -= 1
                  closingElement.potential = none
                  break doubleLoop
                
                elif openingElement.numDelim == 1 and closingElement.numDelim >= 2:
                  
                  resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.potential = none
                  closingElement.numDelim -= 1
                  closingElement.position += 1
                  continue
                
                else:
                  resultDelims.add(@[DelimStack(position: openingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: opener), DelimStack(position: closingElement.position, typeDelim: "emphasis", numDelim: 1, isActive: true, potential: closer)])

                  for element in delimSeq:
                    if element.position in (openingElement.position+1..closingElement.position-1):
                      element.isActive = false

                  openingElement.potential = none
                  closingElement.potential = none
                  break doubleLoop

          continue



    continue

  return resultDelims



proc processEmphasis*(line: string): seq[DelimStack] =
  result =(line.readEmphasisAste & line.readEmphasisUnder)
         .sortedByIt(it.position)
         .parseEmphasis
  


proc parseInline*(line: string): seq[DelimStack] =

  var r = (line.readAutoLink &
   line.readLinkOrImage &
   line.readCodeSpan &
   line.readEmphasisAste &
   line.readEmphasisUnder &
   line.readHardBreak &
   line.readEntity &
   line.readEscape)
   .sortedByIt(it.position)

  #echoObj r

  let n_em = r.parseEscape
              .parseAutoLink(line)
              .parseCodeSpan.parseLink(line)
              .filter(proc(x: DelimStack): bool =
              (x.typeDelim != "*" and x.typeDelim != "_"))

  #echoObj n_em
  #echoObj r
  let em = r.parseEmphasis

  #echoObj em
  #echoObj (n_em & em)

  return (n_em & em)
         .sortedByIt(it.position)
         .filter(proc(x: DelimStack): bool =
         (x.isActive) and
          x.potential != both)
