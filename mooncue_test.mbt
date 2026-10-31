///|
test "safe and suspicious values" {
  assert_eq(@mooncue.cell_reason("hello"), None)
  assert_eq(
    @mooncue.cell_reason("  =1+1"),
    Some("formula marker, possibly after spaces"),
  )
  assert_eq(
    @mooncue.cell_reason(" +12"),
    Some("formula marker, possibly after spaces"),
  )
  assert_eq(
    @mooncue.cell_reason("  \tvalue"),
    Some("control character after leading spaces"),
  )
  assert_eq(@mooncue.cell_reason("普通文字"), None)
}

///|
test "quoted commas newlines and escaped quotes preserve logical row positions" {
  let csv = "\u{FEFF}name,note\r\nAlice,\"ok,\nnext\"\r\nBob,\"=1+\"\"2\"\"\"\r\n"
  let expected : Array[@mooncue.Finding] = [
    { row: 3, column: 2, reason: "formula marker, possibly after spaces", },
  ]
  assert_eq(@mooncue.scan_csv(csv), Ok(expected))
}

///|
test "multiple triggers and final cell" {
  let expected : Array[@mooncue.Finding] = [
    { row: 1, column: 1, reason: "formula marker, possibly after spaces", },
    { row: 2, column: 2, reason: "formula marker, possibly after spaces", },
  ]
  assert_eq(@mooncue.scan_csv("@a,safe\nplain,-1"), Ok(expected))
}

///|
test "malformed csv is rejected" {
  assert_true(@mooncue.scan_csv("a,\"unfinished") is Err(_))
  assert_true(@mooncue.scan_csv("a\"b,c") is Err(_))
  assert_true(@mooncue.scan_csv("\"a\"tail,b") is Err(_))
}

///|
test "limits include empty rows and columns" {
  let limits : @mooncue.Limits = {
    max_chars: 100,
    max_rows: 1,
    max_columns: 2,
    max_cell_chars: 3,
  }
  assert_true(@mooncue.scan_csv("a,b\n", limits~) is Ok(_))
  assert_true(@mooncue.scan_csv("a,b\n\n", limits~) is Err(_))
  assert_true(@mooncue.scan_csv("a,b,c", limits~) is Err(_))
  assert_true(@mooncue.scan_csv("abcd", limits~) is Err(_))
}
