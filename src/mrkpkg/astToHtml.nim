import defBlock, readInline, htmlgen, strutils

proc astToHtml*(mdast: Block, isTight: var bool): string =

  case mdast.kind
  of leafBlock:

    case mdast.leafType

    of themanticBreak: return hr() & "\p"

    of paragraph:
      let value = mdast.raw.strip(leading = false)
      if isTight: return value & "\p"
      else: return p(value) & "\p"

    of header1: return h1(mdast.raw) & "\p"

    of header2: return h2(mdast.raw) & "\p"

    of header3: return h3(mdast.raw) & "\p"

    of header4: return h4(mdast.raw) & "\p"

    of header5: return h5(mdast.raw) & "\p"

    of header6: return h6(mdast.raw) & "\p"

    of htmlBlock: return mdast.raw & "\p"

    of indentedCodeBlock: return pre(code(mdast.raw & "\p")) & "\p"

    of fencedCodeBlock:
      if mdast.raw == "":
        return pre(code(mdast.raw)) & "\p"
      else:
        return pre(code(mdast.raw & "\p")) & "\p"

    else: return

  of containerBlock:

    case mdast.containerType

    of Blocktype.blockQuote:

      var blockQuoteContainer: string
      for child in mdast.children:
        blockQuoteContainer.add(child.astToHtml(isTight))
      return htmlgen.blockquote("\p" & blockquoteContainer) & "\p"

    of Blocktype.list:

      var listContainer: string
      for child in mdast.children:
        listContainer.add(child.astToHtml(isTight))
      return li("\p" & listContainer) & "\p"

    of Blocktype.unOrderedLooseList:

      var unOrderedListContainer: string
      for child in mdast.children:
        unOrderedListContainer.add(child.astToHtml(isTight))
      return ul("\p" & unOrderedListContainer) & "\p"

    of Blocktype.unOrderedTightList:

      isTight = true
      var unOrderedListContainer: string
      for child in mdast.children:
        unOrderedListContainer.add(child.astToHtml(isTight))
      isTight = false
      return ul("\p" & unOrderedListContainer) & "\p"

    of Blocktype.orderedLooseList:

      var orderedListContainer: string
      for child in mdast.children:
        orderedListContainer.add(child.astToHtml(isTight))
      return ol("\p" & orderedListContainer) & "\p"

    of Blocktype.orderedTightList:

      isTight = true
      var orderedListContainer: string
      for child in mdast.children:
        orderedListContainer.add(child.astToHtml(isTight))
      isTight = false
      return ol("\p" & orderedListContainer) & "\p"

    else: return