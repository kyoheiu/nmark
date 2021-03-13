import def, htmlgen

proc astToHtml*(mdast: Block): string =
  case mdast.kind
  of leafBlock:

    case mdast.leafType

    of themanticBreak: return hr() & "\p"

    of paragraph: return p(mdast.inline.value) & "\p"

    of header1: return h1(mdast.inline.value) & "\p"

    of header2: return h2(mdast.inline.value) & "\p"

    of header3: return h3(mdast.inline.value) & "\p"

    of header4: return h4(mdast.inline.value) & "\p"

    of header5: return h5(mdast.inline.value) & "\p"

    of header6: return h6(mdast.inline.value) & "\p"

    of indentedCodeBlock: return pre(code(mdast.inline.value & "\p")) & "\p"

    of fencedCodeBlock:
      if mdast.inline.value == "":
        return pre(code(mdast.inline.value)) & "\p"
      else:
        return pre(code(mdast.inline.value & "\p")) & "\p"

    else: return

  of containerBlock:

    case mdast.containerType

    of BLocktype.blockQuote:

      var blockQuoteContainer: string
      for child in mdast.children:
        blockQuoteContainer.add(child.astToHtml)
        blockquoteContainer = ""
        return htmlgen.blockquote(blockquoteContainer) & "\p"
    
    else: return