use std::fs;
use std::path::Path;
use std::process::Command;

use super::{generate_frozen, lock_versions, repo_root, LOCKS, OUTPUT};

fn io(context: &Path) -> impl Fn(std::io::Error) -> String + '_ {
    move |e| format!("{}: {e}", context.display())
}

fn table(manifest: &Path, header: &str) -> Result<String, String> {
    let text = fs::read_to_string(manifest).map_err(io(manifest))?;
    let start = text
        .lines()
        .position(|line| line.trim() == header)
        .ok_or_else(|| format!("{} has no {header} table", manifest.display()))?;
    let body: Vec<&str> = text
        .lines()
        .skip(start + 1)
        .take_while(|line| !line.trim_start().starts_with('['))
        .collect();
    Ok(body.join("\n"))
}

fn manifest(repo: &Path) -> Result<String, String> {
    let dependencies = table(&repo.join("crates/tumpel-api/Cargo.toml"), "[dependencies]")?;
    let workspace = table(&repo.join("Cargo.toml"), "[workspace.dependencies]")?;
    Ok(format!(
        "[package]\nname = \"frozen-check\"\nversion = \"0.0.0\"\nedition = \"2021\"\npublish = false\n\n[lib]\npath = \"lib.rs\"\n\n[dependencies]\n{dependencies}\n\n[workspace]\n\n[workspace.dependencies]\n{workspace}\n"
    ))
}

#[test]
fn an_older_lock_generates_frozen_types_that_compile() -> Result<(), String> {
    let repo = repo_root();
    let newest = *lock_versions(&repo)?
        .last()
        .ok_or("the repository holds no channel wire lock")?;
    let older = newest - 1;
    let root = repo.join(".tmp/xtask-frozen-test");
    if root.exists() {
        fs::remove_dir_all(&root).map_err(io(&root))?;
    }
    let locks = root.join(LOCKS);
    let krate = root.join(OUTPUT);
    fs::create_dir_all(&locks).map_err(io(&locks))?;
    fs::create_dir_all(&krate).map_err(io(&krate))?;

    let source = repo.join(LOCKS).join(format!("v{newest}.json"));
    let text = fs::read_to_string(&source).map_err(io(&source))?;
    let mut lock: serde_json::Value = serde_json::from_str(&text).map_err(|e| e.to_string())?;
    lock["channelProtocolVersion"] = serde_json::json!(older);
    fs::write(locks.join(format!("v{newest}.json")), &text).map_err(io(&locks))?;
    fs::write(locks.join(format!("v{older}.json")), lock.to_string()).map_err(io(&locks))?;

    generate_frozen(&root)?;

    let modules = fs::read_to_string(krate.join("frozen.rs")).map_err(io(&krate))?;
    assert_eq!(
        modules,
        format!("#[allow(clippy::pedantic, clippy::unwrap_used, clippy::expect_used)]\n#[path = \"frozen/v{older}.rs\"]\npub mod v{older};\n")
    );
    assert!(krate.join(format!("frozen/v{older}.rs")).exists());
    assert!(!krate.join(format!("frozen/v{newest}.rs")).exists());

    fs::write(krate.join("Cargo.toml"), manifest(&repo)?).map_err(io(&krate))?;
    fs::write(krate.join("lib.rs"), "pub mod frozen;\n").map_err(io(&krate))?;
    fs::copy(repo.join("Cargo.lock"), krate.join("Cargo.lock")).map_err(io(&krate))?;
    let checked = Command::new(env!("CARGO"))
        .args(["check", "--quiet", "--manifest-path"])
        .arg(krate.join("Cargo.toml"))
        .env("CARGO_TARGET_DIR", repo.join("target/frozen-check"))
        .output()
        .map_err(|e| format!("running cargo check: {e}"))?;
    let stderr = String::from_utf8_lossy(&checked.stderr).into_owned();
    fs::remove_dir_all(&root).map_err(io(&root))?;
    assert!(
        checked.status.success(),
        "the frozen v{older} types do not compile:\n{stderr}"
    );
    Ok(())
}
