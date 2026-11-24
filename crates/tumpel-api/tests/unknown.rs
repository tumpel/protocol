use tumpel_api::types::{
    ChannelControlEnvelope, SessionState, SubscriptionPauseReason, TenantApiRecordStartRefusalResult, TurnFailureReason,
};

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
}

#[test]
fn known_discriminators_still_choose_the_correct_variant() {
    let reason: SubscriptionPauseReason = serde_json::from_str(r#"{"kind":"CrewFailing","extra":true}"#).unwrap();
    assert!(matches!(reason, SubscriptionPauseReason::CrewFailing(_)));
}

#[test]
fn refusal_recording_preserves_the_tags_that_overflowed() {
    let tags: Vec<_> = (0..17).map(|index| format!("crew:{index}")).collect();
    let value = serde_json::json!({"kind": "TagsOverLimit", "tags": tags});
    let result: TenantApiRecordStartRefusalResult = serde_json::from_value(value.clone()).unwrap();
    assert!(matches!(
        result,
        TenantApiRecordStartRefusalResult::SessionTagsOverLimit(_)
    ));
    assert_eq!(serde_json::to_value(&result).unwrap(), value);
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

#[test]
fn namespaced_channel_discriminators_preserve_unknown_values_and_reject_malformed_known_values() {
    let value = serde_json::json!({"type": "FutureAck", "seq": 1, "extra": true});
    let envelope: ChannelControlEnvelope = serde_json::from_value(value.clone()).unwrap();
    assert_eq!(envelope, ChannelControlEnvelope::Unrecognised(value.clone()));
    assert_eq!(serde_json::to_value(&envelope).unwrap(), value);

    let envelope: ChannelControlEnvelope = serde_json::from_str(r#"{"type":"Ack","seq":1}"#).unwrap();
    assert!(matches!(envelope, ChannelControlEnvelope::Ack(_)));

    for (value, message) in [
        (serde_json::json!({"type": "Ack"}), "missing field `seq`"),
        (
            serde_json::json!({"type": "Ack", "seq": {"future": true}}),
            "invalid type",
        ),
    ] {
        let error = serde_json::from_value::<ChannelControlEnvelope>(value).unwrap_err();
        assert!(error.to_string().contains(message), "{error}");
    }
}
