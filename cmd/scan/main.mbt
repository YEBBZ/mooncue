///|
/// Node wrapper: read bounded UTF-8 input from stdin; no file writes or network.
extern "js" fn read_stdin() -> String =
  #|() => {
  #| try {
  #|  const fs = require('node:fs');
  #|  const chunks = [];
  #|  let total = 0;
  #|  const buffer = Buffer.alloc(65536);
  #|  for (;;) {
  #|    const n = fs.readSync(0, buffer, 0, buffer.length, null);
  #|    if (!n) break;
  #|    total += n;
  #|    if (total > 4000000) throw new Error('input exceeds 4,000,000 byte limit');
  #|    chunks.push(Buffer.from(buffer.subarray(0, n)));
  #|  }
  #|  return new TextDecoder('utf-8', {fatal: true}).decode(Buffer.concat(chunks));
  #| } catch (error) {
  #|   process.stderr.write('Unable to read bounded UTF-8 input: ' + error.message + '\n');
  #|   process.exit(2);
  #| }
  #|}

///|
extern "js" fn set_exit(code : Int32) -> Unit =
  #|(code) => { process.exitCode = code; }

///|
fn main {
  match @guard.scan_csv(read_stdin()) {
    Ok(findings) => {
      for finding in findings {
        println(
          "row \{finding.row}, column \{finding.column}: \{finding.reason}",
        )
      }
      if findings.length() == 0 {
        println("No formula-like cells found by these checks.")
      } else {
        println(
          "Review \{findings.length()} flagged cell(s); this is not a guarantee of safety.",
        )
        set_exit(1)
      }
    }
    Err(error) => {
      println(
        "CSV error at row \{error.row}, column \{error.column}: \{error.message}",
      )
      set_exit(2)
    }
  }
}
