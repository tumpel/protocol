use tumpel_api::types::{ConfigPlan, EventProblem, Problem};
use tumpel_api::{ContainsUnrecognised, ResponseValue};

#[tokio::test]
async fn responses_flag_only_a_nested_unrecognised_value() {
    for (action, unrecognised) in [("FutureAction", true), ("Create", false)] {
        let body = format!(
            r#"{{"changes":[{{"action":"Create","resource":"Persona","name":"first","description":"first change"}},{{"action":"{action}","resource":"Persona","name":"second","description":"second change"}}]}}"#
        );
        let response = reqwest::Response::from(http::Response::new(body));
        let decoded = ResponseValue::<ConfigPlan>::from_response::<Problem>(response)
            .await
            .unwrap();
        assert_eq!(decoded.contains_unrecognised(), unrecognised);
    }
}

#[tokio::test]
async fn typed_refusals_flag_a_nested_unrecognised_code() {
    let body = r#"{"code":"FutureRefusal","title":"Future refusal","detail":"future detail","fix":"future fix"}"#;
    let response = http::Response::builder()
        .status(http::StatusCode::BAD_REQUEST)
        .body(body)
        .unwrap();
    let decoded = ResponseValue::<EventProblem>::from_response::<EventProblem>(response.into())
        .await
        .unwrap();
    assert!(matches!(decoded.as_ref(), EventProblem::Problem(_)));
    assert!(decoded.contains_unrecognised());
}
