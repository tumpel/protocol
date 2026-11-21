use serde_json::{json, Value};
use tumpel_api::types::ChannelDispatchGrant;

fn grant() -> Value {
    json!({
        "credentialHandoverId": "01HZY8Q6V0M1C2D3E4F5G6H7J8",
        "expiresAt": "2026-11-16T12:00:00+00:00",
        "variables": [{ "name": "OPENROUTER_API_KEY", "value": "sk-or" }],
        "connectors": []
    })
}

#[test]
fn a_grant_reads_the_same_with_or_without_arguments() {
    let older: ChannelDispatchGrant = serde_json::from_value(grant()).expect("a grant without arguments reads");
    let mut carrying = grant();
    carrying["arguments"] = json!(["-c", "model_provider=openrouter"]);
    let current: ChannelDispatchGrant = serde_json::from_value(carrying).expect("a grant with arguments reads");
    assert!(older.arguments.is_empty());
    assert_eq!(
        current
            .arguments
            .iter()
            .map(|argument| argument.as_str())
            .collect::<Vec<_>>(),
        ["-c", "model_provider=openrouter"]
    );
    assert_eq!(
        ChannelDispatchGrant {
            arguments: Vec::new(),
            ..current
        },
        older
    );
    let written = serde_json::to_value(&older).expect("the grant writes");
    assert!(written.get("arguments").is_none(), "{written}");
}
