use serde_json::json;
use tumpel_api::types::PersonasListResponse;

#[test]
fn persona_lists_read_both_views_without_losing_default_content() {
    let mut response = json!([{
        "personaId": "persona-test",
        "tenantId": "tenant-test",
        "name": "reviewer",
        "harness": "ClaudeCode",
        "secretSetId": "secret-set-test",
        "connectorIds": [],
        "boxRetention": "Auto",
        "tumpelMcp": true,
        "files": [{
            "path": ".claude/CLAUDE.md",
            "digest": "a".repeat(64),
            "sizeBytes": 6,
            "createdAt": 1000,
            "updatedAt": 2000,
            "source": "Inline",
            "content": "aGVsbG8K"
        }],
        "createdAt": 1000,
        "updatedAt": 2000
    }]);
    let full: PersonasListResponse = serde_json::from_value(response.clone()).expect("the default list reads");
    assert_eq!(serde_json::to_value(full).expect("the full list writes"), response);
    let file = response[0]["files"][0]
        .as_object_mut()
        .expect("the fixture holds a file");
    assert_eq!(file.remove("source"), Some(json!("Inline")));
    assert_eq!(file.remove("content"), Some(json!("aGVsbG8K")));
    let metadata: PersonasListResponse = serde_json::from_value(response.clone()).expect("the metadata list reads");
    assert_eq!(
        serde_json::to_value(metadata).expect("the metadata list writes"),
        response
    );
    let empty: PersonasListResponse = serde_json::from_str("[]").expect("an empty list reads");
    assert_eq!(serde_json::to_value(empty).expect("the empty list writes"), json!([]));
}
