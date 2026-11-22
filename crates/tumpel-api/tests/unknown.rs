use tumpel_api::types::{SessionPromptOrigin, SessionState, SubscriptionPauseReason, TurnFailureReason};

#[test]
fn unknown_values_decode_explicitly_and_preserve_the_wire_value() {
    let state: SessionState = serde_json::from_str(r#""FutureState""#).unwrap();
    assert_eq!(state, SessionState::Unrecognised("FutureState".to_string()));
    assert_eq!(serde_json::to_string(&state).unwrap(), r#""FutureState""#);

    let failure: TurnFailureReason = serde_json::from_str(r#""FutureFailure""#).unwrap();
    assert_eq!(failure, TurnFailureReason::Unrecognised("FutureFailure".to_string()));

    let pause = serde_json::json!({"kind": "FuturePause", "message": "keep this", "extra": true});
    let reason: SubscriptionPauseReason = serde_json::from_value(pause.clone()).unwrap();
    assert_eq!(reason, SubscriptionPauseReason::Unrecognised(pause.clone()));
    assert_eq!(serde_json::to_value(&reason).unwrap(), pause);

    let origin: SessionPromptOrigin = serde_json::from_str(r#"{"kind":"Prompt","extra":{"future":true}}"#).unwrap();
    assert_eq!(origin.kind.to_string(), "Prompt");
}

#[test]
fn known_discriminators_still_choose_the_correct_variant() {
    let reason: SubscriptionPauseReason = serde_json::from_str(r#"{"kind":"CrewFailing","extra":true}"#).unwrap();
    assert!(matches!(reason, SubscriptionPauseReason::CrewFailing(_)));
    let state: SessionState = serde_json::from_str(r#""Idle""#).unwrap();
    assert_eq!(state, SessionState::Idle);
}

#[test]
fn a_known_discriminator_with_a_malformed_payload_is_an_error() {
    for (value, message) in [
        (serde_json::json!({"kind": "DeliveryFailed"}), "missing field `turnId`"),
        (
            serde_json::json!({"kind": "DeliveryFailed", "turnId": {"future": true}}),
            "invalid type",
        ),
    ] {
        let error = serde_json::from_value::<SubscriptionPauseReason>(value).unwrap_err();
        assert!(error.to_string().contains(message), "{error}");
    }
}
