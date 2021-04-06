import htmlgen
import defBlock, insertMarker

proc astToHtml*(mdast: Block, isTight: var bool): string =

  case mdast.kind
  of leafBlock:

    case mdast.leafType

    of themanticBreak: return hr() & "\p"

    of paragraph:
      let value = mdast.raw.insertInline
      if isTight: return value
      else: return p(value) & "\p"

    of header1: return h1(mdast.raw.insertInline) & "\p"

    of header2: return h2(mdast.raw.insertInline) & "\p"

    of header3: return h3(mdast.raw.insertInline) & "\p"

    of header4: return h4(mdast.raw.insertInline) & "\p"

    of header5: return h5(mdast.raw.insertInline) & "\p"

    of header6: return h6(mdast.raw.insertInline) & "\p"

    of htmlBlock: return mdast.raw & "\p"

    of indentedCodeBlock: return pre(code(mdast.raw.tagToLiteral & "\p")) & "\p"

    of fencedCodeBlock:
      if mdast.raw == "":
        return pre(code(mdast.raw.tagToLiteral)) & "\p"
      else:
        return pre(code(mdast.raw.tagToLiteral & "\p")) & "\p"

    else: return

  of containerBlock:

    case mdast.containerType

    of Blocktype.blockQuote:

      var blockQuoteContainer: string
      for child in mdast.children:
        blockQuoteContainer.add(child.astToHtml(isTight))
      return htmlgen.blockquote("\n" & blockquoteContainer) & "\p"

    of Blocktype.list:

      var listContainer: string
      for child in mdast.children:
        listContainer.add(child.astToHtml(isTight))
      return li(listContainer) & "\p"

    of Blocktype.unOrderedLooseList:

      isTight = false
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

      isTight = false
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