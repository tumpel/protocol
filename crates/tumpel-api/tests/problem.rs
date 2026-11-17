use tumpel_api::types::{Problem, ProblemCode};

#[test]
fn a_problem_with_a_code_this_client_does_not_know_still_reads_with_its_title_and_fix() {
    let problem: Problem = serde_json::from_str(
        r#"{"code":"SomethingAddedLater","title":"New refusal","detail":"what failed","fix":"what to do"}"#,
    )
    .expect("an unknown code reads");
    assert_eq!(
        problem.code,
        ProblemCode::Unrecognised("SomethingAddedLater".to_string())
    );
    assert_eq!(problem.code.to_string(), "SomethingAddedLater");
    assert_eq!(problem.title, "New refusal");
    assert_eq!(problem.fix, "what to do");
}

#[test]
fn a_known_code_reads_as_its_own_variant() {
    let problem: Problem =
        serde_json::from_str(r#"{"code":"GitHubAppPermissionMissing","title":"t","detail":"d","fix":"f"}"#)
            .expect("a known code reads");
    assert_eq!(problem.code, ProblemCode::GitHubAppPermissionMissing);
}
