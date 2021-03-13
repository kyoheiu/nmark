import def, htmlgen

proc astToHtml*(mdast: Block): string =
  case mdast.kind
  of leafBlock:

    case mdast.leafType

    of themanticBreak: hr() & "\p"

    of paragraph: p(mdast.inline.value) & "\p"

    of header1: h1(mdast.inline.value) & "\p"

    of header2: h2(mdast.inline.value) & "\p"

    of header3: h3(mdast.inline.value) & "\p"

    of header4: h4(mdast.inline.value) & "\p"

    of header5: h5(mdast.inline.value) & "\p"

    of header6: h6(mdast.inline.value) & "\p"

    of indentedCodeBlock: pre(code(mdast.inline.value & "\p")) & "\p"

    of fencedCodeBlock:
      if mdast.inline.value == "":
        pre(code(mdast.inline.value)) & "\p"
      else:
        pre(code(mdast.inline.value & "\p")) & "\p"

    else: return

  #of containerBlock:

    #case mdast.containerType

    #of BLocktype.blockQuote:
      #var blockQuoteContainer: string
      #for child in mdast.children:
        #astToHtml(blockQuoteContainer, child)
        #resultHtml.add(blockquote(blockquoeteContainer) & "\p")
        #blockquoeteContainer = ""

  else:
    return