#[allow(clippy::pedantic, clippy::unwrap_used, clippy::expect_used)]
#[path = "../generated/generated.rs"]
mod generated;

pub use generated::*;

#[path = "../generated/frozen.rs"]
pub mod frozen;

pub const TENANT_CONFIG_SCHEMA: &str = include_str!("../generated/TenantConfig.json");

mod response;
pub use response::ContainsUnrecognised;
