# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import strutils, json

type 
  Heading = object
    name, kind: string
    level: int
    values: Value
 
  Paragraph = object
    name, kind: string
    values: Value

  Value = object
    name, kind, value: string
  
  Empty = object


when isMainModule:
  let path = readLine(stdin)
  var s = readFile(path)
  var mdast: seq[JsonNode]
  for line in s.splitlines:
    if line.len != 0 and line.splitWhitespace[0] == "#":
      var tempLine = line
      tempLine.delete(0,1)
      let inline = Value(
        name: "text",
        kind: "inline",
        value: tempLine
      )
      let heading = Heading(
        name: "heading",
        kind: "block",
        level: 1,
        values: inline
      )
      mdast.add(%heading)
    elif line.len != 0:
      if line.endsWith("  "):
        var tempLine = line
        tempLine.removeSuffix("  ")
        let inline = Value(
          name: "text",
          kind: "inline",
          value: tempLine
        )
        let paragraph = Paragraph(
          name: "paragraph",
          kind: "inline",
          values: inline
        )
        mdast.add(%paragraph)
        continue
        
      let inline = Value(
        name: "text",
        kind: "inline",
        value: line
      )
      let paragraph = Paragraph(
        name: "paragraph",
        kind: "inline",
        values: inline
      )
      mdast.add(%paragraph)
    else:
      let empty = Empty()
      mdast.add(%empty)
  echo mdast
      
