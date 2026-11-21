use tumpel_api::types::{SessionPromptOrigin, SessionState, SubscriptionPauseReason, TurnFailureReason};

#[test]
fn unknown_values_decode_explicitly_and_preserve_the_wire_value() {
    let state: SessionState = serde_json::from_str(r#""FutureState""#).unwrap();
    assert_eq!(state, SessionState::Unknown("FutureState".to_string()));
    assert_eq!(serde_json::to_string(&state).unwrap(), r#""FutureState""#);

    let failure: TurnFailureReason = serde_json::from_str(r#""FutureFailure""#).unwrap();
    assert_eq!(failure, TurnFailureReason::Unknown("FutureFailure".to_string()));

    let pause = serde_json::json!({"kind": "FuturePause", "message": "keep this", "extra": true});
    let reason: SubscriptionPauseReason = serde_json::from_value(pause.clone()).unwrap();
    assert_eq!(reason, SubscriptionPauseReason::Unknown(pause.clone()));
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
fn an_unrecognised_shape_of_a_known_variant_decodes_as_unknown() {
    let value = serde_json::json!({"kind": "DeliveryFailed", "turnId": {"future": true}});
    let reason: SubscriptionPauseReason = serde_json::from_value(value.clone()).unwrap();
    assert_eq!(reason, SubscriptionPauseReason::Unknown(value));
}
