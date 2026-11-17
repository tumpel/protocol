use std::fs;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use proc_macro2::{Delimiter, Group, TokenStream, TokenTree};
use progenitor_impl::{GenerationSettings, Generator, TypeImpl};
use quote::{format_ident, quote};
use schemars::schema::{InstanceType, SchemaObject};

const OPENAPI: &str = "build/openapi/openapi.json";
const LOCKS: &str = "typespec/channel-wire";
const OUTPUT: &str = "crates/tumpel-api/generated";

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn settings() -> GenerationSettings {
    let mut settings = GenerationSettings::default();
    settings.with_conversion(
        SchemaObject {
            instance_type: Some(InstanceType::String.into()),
            format: Some("date-time".to_string()),
            ..SchemaObject::default()
        },
        "::chrono::DateTime<::chrono::FixedOffset>",
        [TypeImpl::Display, TypeImpl::FromStr].into_iter(),
    );
    settings.with_derive("PartialEq");
    settings
}

fn doc_lines(attribute: &Group) -> Option<Vec<String>> {
    if attribute.delimiter() != Delimiter::Bracket {
        return None;
    }
    let meta: syn::MetaNameValue = syn::parse2(attribute.stream()).ok()?;
    if !meta.path.is_ident("doc") {
        return None;
    }
    let syn::Expr::Lit(syn::ExprLit {
        lit: syn::Lit::Str(text),
        ..
    }) = meta.value
    else {
        return None;
    };
    let text = text.value();
    text.contains('\n').then(|| text.lines().map(str::to_string).collect())
}

fn line_docs(tokens: TokenStream) -> TokenStream {
    let mut output = TokenStream::new();
    let mut trees = tokens.into_iter().peekable();
    while let Some(tree) = trees.next() {
        match tree {
            TokenTree::Punct(pound) if pound.as_char() == '#' => {
                let lines = match trees.peek() {
                    Some(TokenTree::Group(attribute)) => doc_lines(attribute),
                    _ => None,
                };
                let Some(lines) = lines else {
                    output.extend([TokenTree::Punct(pound)]);
                    continue;
                };
                trees.next();
                for line in lines {
                    output.extend(quote! { #[doc = #line] });
                }
            }
            TokenTree::Group(group) => {
                let mut nested = Group::new(group.delimiter(), line_docs(group.stream()));
                nested.set_span(group.span());
                output.extend([TokenTree::Group(nested)]);
            }
            other => output.extend([other]),
        }
    }
    output
}

fn screaming(name: &str) -> String {
    let mut screamed = String::new();
    for (index, letter) in name.chars().enumerate() {
        if index > 0 && letter.is_ascii_uppercase() {
            screamed.push('_');
        }
        screamed.push(letter.to_ascii_uppercase());
    }
    screamed
}

type NamedValues = (Vec<String>, Vec<i64>);

fn bound_values(name: &str, schema: &openapiv3::Schema) -> Result<Option<NamedValues>, String> {
    let Some(names) = schema.schema_data.extensions.get("x-bound-names") else {
        return Ok(None);
    };
    let openapiv3::SchemaKind::Type(openapiv3::Type::Integer(integer)) = &schema.schema_kind else {
        return Err(format!(
            "{name} carries x-bound-names but is no integer. Fix: its scalar in typespec/lib."
        ));
    };
    let names: Vec<String> = serde_json::from_value(names.clone())
        .map_err(|e| format!("{name} x-bound-names is not a list of names: {e}."))?;
    let (Some(minimum), Some(maximum)) = (integer.minimum, integer.maximum) else {
        return Err(format!(
            "{name} carries x-bound-names without both bounds. Fix: give it @minValue and @maxValue."
        ));
    };
    Ok(Some((names, vec![minimum, maximum])))
}

fn named_values(name: &str, schema: &openapiv3::Schema) -> Result<Option<NamedValues>, String> {
    let Some(names) = schema.schema_data.extensions.get("x-enum-varnames") else {
        return bound_values(name, schema);
    };
    let openapiv3::SchemaKind::Type(openapiv3::Type::Integer(integer)) = &schema.schema_kind else {
        return Err(format!(
            "{name} carries x-enum-varnames but is no integer enum. Fix: typespec/npm-scripts/enum-names.mjs."
        ));
    };
    let names: Vec<String> = serde_json::from_value(names.clone())
        .map_err(|e| format!("{name} x-enum-varnames is not a list of names: {e}."))?;
    let values: Vec<i64> = integer
        .enumeration
        .iter()
        .copied()
        .collect::<Option<_>>()
        .ok_or_else(|| format!("{name} lists a null enum value."))?;
    Ok(Some((names, values)))
}

fn enum_constants(spec: &openapiv3::OpenAPI) -> Result<TokenStream, String> {
    let mut tokens = TokenStream::new();
    let Some(components) = &spec.components else {
        return Ok(tokens);
    };
    for (name, schema) in &components.schemas {
        let openapiv3::ReferenceOr::Item(schema) = schema else {
            continue;
        };
        let Some((names, values)) = named_values(name, schema)? else {
            continue;
        };
        if names.len() != values.len() {
            return Err(format!(
                "{name} names {} of its {} enum values.",
                names.len(),
                values.len()
            ));
        }
        let width = if values.iter().all(|value| u16::try_from(*value).is_ok()) {
            quote!(u16)
        } else {
            quote!(i64)
        };
        let type_name = format_ident!("{}", name.replace(|letter: char| !letter.is_ascii_alphanumeric(), ""));
        let constants = names.iter().zip(&values).map(|(member, value)| {
            let constant = format_ident!("{}", screaming(member));
            let literal = proc_macro2::Literal::i64_unsuffixed(*value);
            quote! { pub const #constant: #width = #literal; }
        });
        tokens.extend(quote! { impl types::#type_name { #(#constants)* } });
    }
    Ok(tokens)
}

const OPEN_ENUMS: [&str; 1] = ["ProblemCode"];

fn implements(implemented: &syn::ItemImpl, type_name: &str, trait_name: &str) -> bool {
    let self_named = matches!(&*implemented.self_ty, syn::Type::Path(path) if path.path.is_ident(type_name));
    let trait_named = implemented
        .trait_
        .as_ref()
        .and_then(|(path, _)| path.segments.last())
        .is_some_and(|segment| segment.ident == trait_name);
    self_named && trait_named
}

fn without_copy(attribute: &mut syn::Attribute) -> Result<(), String> {
    if !attribute.path().is_ident("derive") {
        return Ok(());
    }
    let derived = attribute
        .parse_args_with(syn::punctuated::Punctuated::<syn::Path, syn::Token![,]>::parse_terminated)
        .map_err(|e| format!("progenitor emitted a derive list syn cannot read: {e}."))?;
    let kept = derived
        .into_iter()
        .filter(|path| path.segments.last().is_none_or(|segment| segment.ident != "Copy"));
    *attribute = syn::parse_quote!(#[derive(#(#kept),*)]);
    Ok(())
}

fn display_unrecognised(implemented: &mut syn::ItemImpl) -> bool {
    let Some(syn::ImplItem::Fn(fmt)) = implemented.items.first_mut() else {
        return false;
    };
    let Some(syn::Stmt::Expr(syn::Expr::Match(matched), _)) = fmt.block.stmts.last_mut() else {
        return false;
    };
    matched
        .arms
        .push(syn::parse_quote!(Self::Unrecognised(ref code) => f.write_str(code)));
    true
}

fn open_enum(items: &mut [syn::Item], name: &str) -> Result<(), String> {
    let mut opened = false;
    let mut displayed = false;
    for item in items {
        match item {
            syn::Item::Enum(declared) if declared.ident == name => {
                for attribute in &mut declared.attrs {
                    without_copy(attribute)?;
                }
                declared.variants.push(syn::parse_quote!(
                    #[serde(untagged)]
                    Unrecognised(::std::string::String)
                ));
                opened = true;
            }
            syn::Item::Impl(implemented) if implements(implemented, name, "Display") => {
                displayed = display_unrecognised(implemented);
            }
            _ => {}
        }
    }
    if opened && displayed {
        return Ok(());
    }
    Err(format!(
        "progenitor emitted no enum {name} with a Display match to open. Fix: crates/xtask OPEN_ENUMS."
    ))
}

fn open_enums(file: &mut syn::File) -> Result<(), String> {
    let types = file
        .items
        .iter_mut()
        .find_map(|item| match item {
            syn::Item::Mod(module) if module.ident == "types" => module.content.as_mut().map(|(_, items)| items),
            _ => None,
        })
        .ok_or("progenitor emitted no types module.")?;
    OPEN_ENUMS.iter().try_for_each(|name| open_enum(types, name))
}

fn read_spec(root: &Path) -> Result<openapiv3::OpenAPI, String> {
    let input = root.join(OPENAPI);
    let text = fs::read_to_string(&input)
        .map_err(|e| format!("reading {}: {e}. Fix: run 'npm run generate'.", input.display()))?;
    serde_json::from_str(&text).map_err(|e| {
        format!(
            "parsing {} as OpenAPI 3.0: {e}. Fix: check the openapi3 emitter output.",
            input.display()
        )
    })
}

fn generate_file(spec: &openapiv3::OpenAPI) -> Result<syn::File, String> {
    let tokens = Generator::new(&settings())
        .generate_tokens(spec)
        .map_err(|e| format!("progenitor rejected openapi.json: {e}. Fix: adjust typespec/main.tsp."))?;
    let mut tokens = line_docs(tokens);
    tokens.extend(enum_constants(spec)?);
    syn::parse2(tokens).map_err(|e| format!("progenitor emitted invalid Rust: {e}."))
}

fn write_file(output: &Path, file: &syn::File) -> Result<(), String> {
    fs::write(output, prettyplease::unparse(file)).map_err(|e| format!("writing {}: {e}.", output.display()))
}

fn lock_version(name: &str) -> Option<u32> {
    name.strip_prefix('v')?.strip_suffix(".json")?.parse().ok()
}

fn lock_versions(root: &Path) -> Result<Vec<u32>, String> {
    let dir = root.join(LOCKS);
    let mut versions = Vec::new();
    for entry in
        fs::read_dir(&dir).map_err(|e| format!("reading {}: {e}. Fix: run 'npm run generate'.", dir.display()))?
    {
        let entry = entry.map_err(|e| format!("reading {}: {e}.", dir.display()))?;
        versions.extend(entry.file_name().to_str().and_then(lock_version));
    }
    versions.sort_unstable();
    Ok(versions)
}

fn lock_spec(root: &Path, version: u32) -> Result<openapiv3::OpenAPI, String> {
    let lock = root.join(LOCKS).join(format!("v{version}.json"));
    let text = fs::read_to_string(&lock).map_err(|e| format!("reading {}: {e}.", lock.display()))?;
    let parsed: serde_json::Value =
        serde_json::from_str(&text).map_err(|e| format!("parsing {}: {e}.", lock.display()))?;
    let schemas = parsed.get("schemas").cloned().ok_or_else(|| {
        format!(
            "{} has no schemas object. Fix: restore it from origin/main.",
            lock.display()
        )
    })?;
    serde_json::from_value(serde_json::json!({
        "openapi": "3.0.0",
        "info": { "title": format!("Tumpel channel protocol {version}"), "version": version.to_string() },
        "paths": {},
        "components": { "schemas": schemas },
    }))
    .map_err(|e| format!("{} does not hold OpenAPI 3.0 schemas: {e}.", lock.display()))
}

fn generate_frozen(root: &Path) -> Result<(), String> {
    let versions = lock_versions(root)?;
    let frozen = versions.split_last().map_or(&[][..], |(_, frozen)| frozen);
    let dir = root.join(OUTPUT).join("frozen");
    if dir.exists() {
        fs::remove_dir_all(&dir).map_err(|e| format!("removing {}: {e}.", dir.display()))?;
    }
    if !frozen.is_empty() {
        fs::create_dir_all(&dir).map_err(|e| format!("creating {}: {e}.", dir.display()))?;
    }
    for version in frozen {
        let file = types_only(generate_file(&lock_spec(root, *version)?)?)?;
        write_file(&dir.join(format!("v{version}.rs")), &file)?;
    }
    let modules = frozen
        .iter()
        .map(|version| {
            format!("#[allow(clippy::pedantic, clippy::unwrap_used, clippy::expect_used)]\n#[path = \"frozen/v{version}.rs\"]\npub mod v{version};\n")
        })
        .collect::<Vec<_>>()
        .concat();
    let output = root.join(OUTPUT).join("frozen.rs");
    fs::write(&output, modules).map_err(|e| format!("writing {}: {e}.", output.display()))
}

fn generate_api(root: &Path) -> Result<(), String> {
    let spec = read_spec(root)?;
    let mut file = generate_file(&spec)?;
    open_enums(&mut file)?;
    let output = root.join(OUTPUT);
    fs::create_dir_all(&output).map_err(|e| format!("creating {}: {e}.", output.display()))?;
    write_file(&output.join("generated.rs"), &file)?;
    generate_frozen(root)
}

fn types_only(mut file: syn::File) -> Result<syn::File, String> {
    file.items.retain(|item| match item {
            syn::Item::Mod(module) => module.ident == "types",
            syn::Item::Impl(implemented) => {
                matches!(&*implemented.self_ty, syn::Type::Path(path) if path.path.segments.first().is_some_and(|segment| segment.ident == "types"))
            }
            _ => false,
        });
    let types = file
        .items
        .iter_mut()
        .find_map(|item| match item {
            syn::Item::Mod(module) => module.content.as_mut().map(|(_, items)| items),
            _ => None,
        })
        .ok_or("progenitor emitted no types module.")?;
    for name in OPEN_ENUMS {
        let declared = types
            .iter()
            .any(|item| matches!(item, syn::Item::Enum(declared) if declared.ident == name));
        if declared {
            open_enum(types, name)?;
        }
    }
    Ok(file)
}

fn main() -> ExitCode {
    let task = std::env::args().nth(1);
    let result = match task.as_deref() {
        Some("generate-api") => generate_api(&repo_root()),
        _ => Err("usage: cargo run -p xtask -- generate-api".to_string()),
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("xtask: {message}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(test)]
mod tests;
