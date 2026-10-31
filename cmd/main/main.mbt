///|
/// A self-contained demonstration that does not read or publish any user data.
fn main {
  let example = "name,note\nAlice,hello\nBob,\"=1+1\"\n"
  match @lib.scan_csv(example) {
    Ok(findings) =>
      for finding in findings {
        println(
          "row \{finding.row}, column \{finding.column}: \{finding.reason}",
        )
      }
    Err(error) => println("CSV error: \{error.message}")
  }
}
