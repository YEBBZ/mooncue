///|
/// A 1-based cell location and an explanation, without exposing its contents.
pub(all) struct Finding {
  row : Int32
  column : Int32
  reason : String
} derive(Eq, Debug)

///|
pub extend Finding with Eq::{not_equal, equal}

///|
pub extend Finding with @debug.Debug::{to_repr}

///|
pub(all) struct CsvError {
  row : Int32
  column : Int32
  message : String
} derive(Eq, Debug)

///|
pub extend CsvError with Eq::{not_equal, equal}

///|
pub extend CsvError with @debug.Debug::{to_repr}

///|
pub(all) struct Limits {
  max_chars : Int32
  max_rows : Int32
  max_columns : Int32
  max_cell_chars : Int32
}

///|
pub fn Limits::default() -> Limits {
  {
    max_chars: 1000000,
    max_rows: 100000,
    max_columns: 1000,
    max_cell_chars: 100000,
  }
}

///|
/// Flag text that may be interpreted as a formula by spreadsheet software.
pub fn cell_reason(cell : String) -> String? {
  let chars = cell.to_array()
  if chars.length() == 0 {
    return None
  }
  let first = chars[0]
  if first == '\t' || first == '\r' || first == '\n' {
    return Some("leading control character")
  }
  let mut i = 0
  while i < chars.length() && chars[i] == ' ' {
    i += 1
  }
  if i < chars.length() &&
    (chars[i] == '\t' || chars[i] == '\r' || chars[i] == '\n') {
    return Some("control character after leading spaces")
  }
  if i < chars.length() &&
    (chars[i] == '=' || chars[i] == '+' || chars[i] == '-' || chars[i] == '@') {
    return Some("formula marker, possibly after spaces")
  }
  None
}

///|
/// Strict CSV scanner. Commas, escaped quotes, and newlines inside quotes are
/// supported. Reports locations, not file contents. Does not modify or run CSV.
pub fn scan_csv(
  input : String,
  limits~ : Limits = Limits::default(),
) -> Result[Array[Finding], CsvError] {
  let chars = input.to_array()
  let findings : Array[Finding] = []
  let mut row = 1
  let mut col = 1
  if limits.max_chars < 1 ||
    limits.max_rows < 1 ||
    limits.max_columns < 1 ||
    limits.max_cell_chars < 1 {
    return Err({ row, column: col, message: "limits must be positive", })
  }
  if chars.length() > limits.max_chars {
    return Err({ row, column: col, message: "input exceeds character limit", })
  }
  let mut i = 0
  if chars.length() > 0 && chars[0] == '\u{FEFF}' {
    i = 1
  }
  let mut cell : Array[Char] = []
  let mut quoted = false
  let mut closed = false
  let mut started = false
  let mut ended_row = false
  while i < chars.length() {
    let c = chars[i]
    ended_row = false
    if row > limits.max_rows {
      return Err({ row, column: col, message: "row limit exceeded", })
    }
    if quoted {
      if c == '"' {
        if i + 1 < chars.length() && chars[i + 1] == '"' {
          cell.push('"')
          i += 1
        } else {
          quoted = false
          closed = true
        }
      } else {
        cell.push(c)
      }
    } else if c == ',' || c == '\n' || c == '\r' {
      match cell_reason(String::from_array(cell[:])) {
        Some(reason) => findings.push({ row, column: col, reason, })
        None => ()
      }
      cell = []
      started = false
      closed = false
      if c == ',' {
        col += 1
        if col > limits.max_columns {
          return Err({ row, column: col, message: "column limit exceeded", })
        }
      } else {
        if c == '\r' && i + 1 < chars.length() && chars[i + 1] == '\n' {
          i += 1
        }
        row += 1
        col = 1
        ended_row = true
      }
    } else if c == '"' {
      if started || closed {
        return Err({ row, column: col, message: "unexpected quote", })
      }
      quoted = true
      started = true
    } else {
      if closed {
        return Err({ row, column: col, message: "text after closing quote", })
      }
      started = true
      cell.push(c)
    }
    if cell.length() > limits.max_cell_chars {
      return Err({ row, column: col, message: "cell limit exceeded", })
    }
    i += 1
  }
  if quoted {
    return Err({ row, column: col, message: "unclosed quote", })
  }
  if !ended_row && chars.length() > 0 {
    match cell_reason(String::from_array(cell[:])) {
      Some(reason) => findings.push({ row, column: col, reason, })
      None => ()
    }
  }
  Ok(findings)
}
