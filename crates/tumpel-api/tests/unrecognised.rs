use tumpel_api::types::{ConfigPlan, TenantEvent};
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
fn tenant_events_flag_unrecognised_discriminators_and_payloads() -> serde_json::Result<()> {
    let unknown_event = r#"{"event":"FutureEvent"}"#;
    assert!(serde_json::from_str::<TenantEvent>(unknown_event)?.contains_unrecognised());

    let capacity_available = r#"{"event":"CapacityAvailable","code":"FutureCapacityCode","createdAt":1,"eventId":1,"hostId":"host","tenantId":"tenant"}"#;
    let event = serde_json::from_str::<TenantEvent>(capacity_available)?;
    assert!(matches!(event, TenantEvent::CapacityAvailableEvent(_)));
    assert!(event.contains_unrecognised());
    Ok(())
}
