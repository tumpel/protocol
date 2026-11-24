use tumpel_api::types::{ConfigPlan, EventProblem};
use tumpel_api::ContainsUnrecognised;

#[test]
fn config_plans_flag_nested_unrecognised_values() -> serde_json::Result<()> {
    for (action, unrecognised) in [("FutureAction", true), ("Create", false)] {
        let body = format!(
            r#"{{"changes":[{{"action":"Create","resource":"Persona","name":"first","description":"first change"}},{{"action":"{action}","resource":"Persona","name":"second","description":"second change"}}]}}"#
        );
        assert_eq!(
            serde_json::from_str::<ConfigPlan>(&body)?.contains_unrecognised(),
            unrecognised
        );
    }
    Ok(())
}

#[test]
fn event_problems_flag_nested_unrecognised_codes() -> serde_json::Result<()> {
    let body = r#"{"code":"FutureRefusal","title":"Future refusal","detail":"future detail","fix":"future fix"}"#;
    assert!(serde_json::from_str::<EventProblem>(body)?.contains_unrecognised());
    Ok(())
}
