use tumpel_api::types::{ConfigPlan, EventProblem, SessionState, SubscriptionPauseReason};
use tumpel_api::{Error, ResponseValue};

#[tokio::test]
async fn responses_record_unknown_enums_and_reset_the_bit_for_each_decode() {
    for (body, unrecognised) in [(r#""FutureState""#, true), (r#""Idle""#, false)] {
        let response = reqwest::Response::from(http::Response::new(body));
        let decoded = ResponseValue::<SessionState>::from_response::<()>(response)
            .await
            .unwrap();
        assert_eq!(decoded.is_unrecognised(), unrecognised);
        assert_eq!(serde_json::to_string(&*decoded).unwrap(), body);
    }
}

#[tokio::test]
async fn responses_record_unknown_values_inside_nested_collections() {
    let body = r#"{"changes":[{"action":"Create","resource":"Persona","name":"known","description":"known change"},{"action":"FutureAction","resource":"FutureResource","name":"future","description":"future change"}]}"#;
    let response = reqwest::Response::from(http::Response::new(body));
    let decoded = ResponseValue::<ConfigPlan>::from_response::<()>(response)
        .await
        .unwrap();
    assert!(decoded.is_unrecognised());
    assert_eq!(
        serde_json::to_value(decoded.into_inner()).unwrap(),
        serde_json::from_str::<serde_json::Value>(body).unwrap()
    );
}

#[tokio::test]
async fn responses_record_unknown_discriminators_without_losing_known_values() {
    let body = r#"[{"kind":"CrewFailing"},{"kind":"FuturePause","extra":true}]"#;
    let response = reqwest::Response::from(http::Response::new(body));
    let decoded = ResponseValue::<Vec<SubscriptionPauseReason>>::from_response::<()>(response)
        .await
        .unwrap();
    assert!(decoded.is_unrecognised());
    assert!(matches!(decoded[0], SubscriptionPauseReason::CrewFailing(_)));
    assert_eq!(
        serde_json::to_value(decoded.into_inner()).unwrap(),
        serde_json::from_str::<serde_json::Value>(body).unwrap()
    );
}

#[tokio::test]
async fn failed_decodes_do_not_mark_the_next_response_as_unrecognised() {
    let response = reqwest::Response::from(http::Response::new(r#"["FutureState",42]"#));
    let error = ResponseValue::<Vec<SessionState>>::from_response::<()>(response)
        .await
        .unwrap_err();
    assert!(matches!(error, Error::InvalidResponsePayload(_, _)));
    let response = reqwest::Response::from(http::Response::new(r#"["Idle"]"#));
    let decoded = ResponseValue::<Vec<SessionState>>::from_response::<()>(response)
        .await
        .unwrap();
    assert!(!decoded.is_unrecognised());
}

#[tokio::test]
async fn abandoned_untagged_variants_do_not_mark_a_known_value_as_unrecognised() {
    let body = r#"{"code":"SignedOut","title":"Sign in","detail":"no token","fix":"sign in again"}"#;
    let response = reqwest::Response::from(http::Response::new(body));
    let decoded = ResponseValue::<EventProblem>::from_response::<()>(response)
        .await
        .unwrap();
    assert!(matches!(*decoded, EventProblem::Problem(_)));
    assert!(!decoded.is_unrecognised());
}

#[test]
fn a_generated_download_response_keeps_the_consuming_stream_api() {
    let client = tumpel_api::Client::new("https://example.test").unwrap();
    let download = async { client.releases_install().await.unwrap().into_inner_stream() };
    drop(download);
}

#[tokio::test]
async fn consuming_a_stream_response_preserves_its_bytes() {
    let response = reqwest::Response::from(http::Response::new("download bytes"));
    let response = ResponseValue::stream(response);
    assert!(!response.is_unrecognised());
    let mut stream = response.into_inner_stream();
    let bytes = std::future::poll_fn(|cx| stream.as_mut().poll_next(cx))
        .await
        .unwrap()
        .unwrap();
    assert_eq!(&bytes[..], b"download bytes");
    assert!(std::future::poll_fn(|cx| stream.as_mut().poll_next(cx)).await.is_none());
}
