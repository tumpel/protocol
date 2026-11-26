use tumpel_api::types::{ClaudeSetupHarness, ClaudeSetupMember, GuestHarnessProtocol, Harness, InstallRecipe};

#[test]
fn the_gemini_harness_values_decode_as_known_variants() -> serde_json::Result<()> {
    assert_eq!(serde_json::from_str::<Harness>(r#""Gemini""#)?, Harness::Gemini);
    assert_eq!(
        serde_json::from_str::<ClaudeSetupHarness>(r#""Gemini""#)?,
        ClaudeSetupHarness::Gemini
    );
    assert_eq!(
        serde_json::from_str::<ClaudeSetupMember>(r#""GEMINI_OAUTH_CREDS_JSON""#)?,
        ClaudeSetupMember::GeminiOauthCredsJson
    );
    assert_eq!(
        serde_json::from_str::<GuestHarnessProtocol>(r#""GeminiStreamJson""#)?,
        GuestHarnessProtocol::GeminiStreamJson
    );
    Ok(())
}

#[test]
fn a_zip_install_recipe_decodes_as_the_zip_variant() -> serde_json::Result<()> {
    let recipe = r#"{"kind":"Zip","stripComponents":0,"archives":[{"architecture":"Amd64","url":"https://example.com/gemini-cli-bundle.zip","sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","binaryPath":"gemini.js","siblingBinaryPaths":[]}]}"#;
    let InstallRecipe::ZipInstallRecipe(zip) = serde_json::from_str::<InstallRecipe>(recipe)? else {
        panic!("expected the Zip variant");
    };
    assert_eq!(zip.archives[0].binary_path.as_str(), "gemini.js");
    Ok(())
}
