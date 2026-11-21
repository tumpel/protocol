/// Types used as operation parameters and responses.
#[allow(clippy::all)]
pub mod types {
    ///The base image of a layered boot, the current release's ReleaseBaseImage for the host's
    ///architecture. `imageUrl`, `kernelUrl` and `manifestUrl` are presigned GETs of the ext4 image, the
    ///kernel and the BaseImageManifest document stored under `imageDigest`, `kernelDigest` and
    ///`manifestDigest` in the release bucket.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelBaseImageDownload {
        #[serde(rename = "imageDigest")]
        pub image_digest: Sha256Digest,
        #[serde(rename = "imageUrl")]
        pub image_url: ::std::string::String,
        #[serde(rename = "kernelDigest")]
        pub kernel_digest: Sha256Digest,
        #[serde(rename = "kernelUrl")]
        pub kernel_url: ::std::string::String,
        #[serde(rename = "manifestDigest")]
        pub manifest_digest: Sha256Digest,
        #[serde(rename = "manifestUrl")]
        pub manifest_url: ::std::string::String,
    }
    ///What a box boots from: a full guest image, or a base image with a harness layer.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(untagged)]
    pub enum ChannelBootImage {
        GuestImageDownload(ChannelGuestImageDownload),
        LayeredImageDownload(ChannelLayeredImageDownload),
    }
    impl ::std::convert::From<ChannelGuestImageDownload> for ChannelBootImage {
        fn from(value: ChannelGuestImageDownload) -> Self {
            Self::GuestImageDownload(value)
        }
    }
    impl ::std::convert::From<ChannelLayeredImageDownload> for ChannelBootImage {
        fn from(value: ChannelLayeredImageDownload) -> Self {
            Self::LayeredImageDownload(value)
        }
    }
    ///Asks the host to drop a box of a session that moved to another host, even when the box holds a
    ///completed turn no snapshot holds, or of a session whose repository the box could not clone. The host answers BoxGone, also when it runs no such box.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelBoxDiscard {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "sessionId")]
        pub session_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelBoxDiscardType,
    }
    ///`ChannelBoxDiscardType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelBoxDiscardType {
        BoxDiscard,
    }
    impl ::std::fmt::Display for ChannelBoxDiscardType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::BoxDiscard => f.write_str("BoxDiscard"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelBoxDiscardType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "BoxDiscard" => Ok(Self::BoxDiscard),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelBoxDiscardType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelBoxDiscardType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host runs no box of the session any more and returned its TAP device to the pool.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelBoxGone {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "sessionId")]
        pub session_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelBoxGoneType,
    }
    ///`ChannelBoxGoneType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelBoxGoneType {
        BoxGone,
    }
    impl ::std::fmt::Display for ChannelBoxGoneType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::BoxGone => f.write_str("BoxGone"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelBoxGoneType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "BoxGone" => Ok(Self::BoxGone),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelBoxGoneType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelBoxGoneType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Asks the host to tear down the box of a session once a snapshot holds its last completed turn.
    ///The host answers BoxGone, also when it runs no box of the session with that boxId, or BoxTeardownFailed.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelBoxTeardown {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "sessionId")]
        pub session_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelBoxTeardownType,
    }
    ///The host kept the box. `detail` states what failed and what fixes it.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelBoxTeardownFailed {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        pub detail: ::std::string::String,
        #[serde(rename = "failedAt")]
        pub failed_at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub reason: ChannelBoxTeardownFailureReason,
        #[serde(rename = "sessionId")]
        pub session_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelBoxTeardownFailedType,
    }
    ///`ChannelBoxTeardownFailedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelBoxTeardownFailedType {
        BoxTeardownFailed,
    }
    impl ::std::fmt::Display for ChannelBoxTeardownFailedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::BoxTeardownFailed => f.write_str("BoxTeardownFailed"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelBoxTeardownFailedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "BoxTeardownFailed" => Ok(Self::BoxTeardownFailed),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelBoxTeardownFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelBoxTeardownFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Why the host kept a box it was asked to tear down.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelBoxTeardownFailureReason {
        BoxDirty,
    }
    impl ::std::fmt::Display for ChannelBoxTeardownFailureReason {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::BoxDirty => f.write_str("BoxDirty"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelBoxTeardownFailureReason {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "BoxDirty" => Ok(Self::BoxDirty),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelBoxTeardownFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelBoxTeardownFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`ChannelBoxTeardownType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelBoxTeardownType {
        BoxTeardown,
    }
    impl ::std::fmt::Display for ChannelBoxTeardownType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::BoxTeardown => f.write_str("BoxTeardown"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelBoxTeardownType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "BoxTeardown" => Ok(Self::BoxTeardown),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelBoxTeardownType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelBoxTeardownType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The first message on every connection, from the control plane: a fresh nonce, the unpadded
    ///base64url encoding of 32 random bytes, that the host must sign. A connection that sends anything
    ///but Hello next is closed.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelChallenge {
        pub nonce: ChannelChallengeNonce,
        #[serde(rename = "type")]
        pub type_: ChannelChallengeType,
    }
    ///`ChannelChallengeNonce`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelChallengeNonce(::std::string::String);
    impl ChannelChallengeNonce {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelChallengeNonce {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelChallengeNonce {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelChallengeNonce {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelChallengeNonce {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelChallengeNonce> for ::std::string::String {
        fn from(value: ChannelChallengeNonce) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelChallengeNonce {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 43usize {
                return Err("ChannelChallengeNonce: shorter than 43 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelChallengeNonce {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelChallengeNonce {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelChallengeNonce {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelChallengeType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelChallengeType {
        Challenge,
    }
    impl ::std::fmt::Display for ChannelChallengeType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Challenge => f.write_str("Challenge"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelChallengeType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Challenge" => Ok(Self::Challenge),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelChallengeType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelChallengeType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Where one chunk is stored: the chunk whose bytes have the lower-case hex SHA-256 `digest` lies
    ///`length` bytes long at byte `offset` of the pack `packDigest`. A pack is chunks concatenated, about
    ///8 MiB of them, stored under `<tenantId>/packs/<packDigest>`, where `packDigest` is the SHA-256 of
    ///the whole pack.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelChunkPlacement {
        pub digest: Sha256Digest,
        pub length: ::std::num::NonZeroU32,
        pub offset: i64,
        #[serde(rename = "packDigest")]
        pub pack_digest: Sha256Digest,
    }
    ///The code the person submitted, for the standard input of the setup's `claude setup-token`; the
    ///host forwards it to the box once and keeps no copy. The box fails the setup MintTimedOut when
    ///Claude Code prints no token within `mintBudgetSeconds` of the code.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelClaudeSetupBoxCode {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "claudeSetupId")]
        pub claude_setup_id: EntityId,
        pub code: ClaudeSetupCodeText,
        #[serde(rename = "mintBudgetSeconds")]
        pub mint_budget_seconds: ::std::num::NonZeroU32,
        #[serde(rename = "type")]
        pub type_: ChannelClaudeSetupBoxCodeType,
    }
    ///`ChannelClaudeSetupBoxCodeType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelClaudeSetupBoxCodeType {
        ClaudeSetupBoxCode,
    }
    impl ::std::fmt::Display for ChannelClaudeSetupBoxCodeType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ClaudeSetupBoxCode => f.write_str("ClaudeSetupBoxCode"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelClaudeSetupBoxCodeType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ClaudeSetupBoxCode" => Ok(Self::ClaudeSetupBoxCode),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelClaudeSetupBoxCodeType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelClaudeSetupBoxCodeType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Asks the host to stop the setup's box and delete its drive, also in place of an unacked offer or
    ///code of a setup that ended. The host answers nothing, and does nothing when it runs no such box.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelClaudeSetupBoxDiscard {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "claudeSetupId")]
        pub claude_setup_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelClaudeSetupBoxDiscardType,
    }
    ///`ChannelClaudeSetupBoxDiscardType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelClaudeSetupBoxDiscardType {
        ClaudeSetupBoxDiscard,
    }
    impl ::std::fmt::Display for ChannelClaudeSetupBoxDiscardType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ClaudeSetupBoxDiscard => f.write_str("ClaudeSetupBoxDiscard"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelClaudeSetupBoxDiscardType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ClaudeSetupBoxDiscard" => Ok(Self::ClaudeSetupBoxDiscard),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelClaudeSetupBoxDiscardType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelClaudeSetupBoxDiscardType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The setup's box stopped without storing the token and is gone. `detail` states what failed and
    ///what fixes it, and never holds the token.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelClaudeSetupBoxFailed {
        #[serde(rename = "claudeSetupId")]
        pub claude_setup_id: EntityId,
        pub detail: ::std::string::String,
        #[serde(rename = "failedAt")]
        pub failed_at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub reason: ClaudeSetupFailureReason,
        #[serde(rename = "type")]
        pub type_: ChannelClaudeSetupBoxFailedType,
    }
    ///`ChannelClaudeSetupBoxFailedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelClaudeSetupBoxFailedType {
        ClaudeSetupBoxFailed,
    }
    impl ::std::fmt::Display for ChannelClaudeSetupBoxFailedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ClaudeSetupBoxFailed => f.write_str("ClaudeSetupBoxFailed"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelClaudeSetupBoxFailedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ClaudeSetupBoxFailed" => Ok(Self::ClaudeSetupBoxFailed),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelClaudeSetupBoxFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelClaudeSetupBoxFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Asks the host to boot box `boxId` from `image` with no repository, no persona files and no
    ///credential, and run `claude setup-token` in it for Claude setup `claudeSetupId`. The host answers
    ///ClaudeSetupBoxUrl once the command prints its sign-in URL, hands the code of a ClaudeSetupBoxCode
    ///to the command's standard input, and answers ClaudeSetupBoxFailed when the box stops without
    ///storing the token. Only the box writes the token: it POSTs it to `tokenUrl` with `tokenCredential`
    ///as its bearer token, and the host never sees it. `tokenCredential` is bound to this setup and
    ///writes its token once, while the setup is Minting. The host stops the box at `expiresAt`, when it stores the token, or on
    ///ClaudeSetupBoxDiscard, and deletes its drive.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelClaudeSetupBoxOffer {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "claudeSetupId")]
        pub claude_setup_id: EntityId,
        #[serde(rename = "expiresAt")]
        pub expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "harnessVersion")]
        pub harness_version: HarnessVersion,
        pub image: ChannelBootImage,
        #[serde(rename = "tenantId")]
        pub tenant_id: EntityId,
        #[serde(rename = "tokenCredential")]
        pub token_credential: ChannelClaudeSetupBoxOfferTokenCredential,
        #[serde(rename = "tokenUrl")]
        pub token_url: ::std::string::String,
        #[serde(rename = "type")]
        pub type_: ChannelClaudeSetupBoxOfferType,
    }
    ///`ChannelClaudeSetupBoxOfferTokenCredential`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelClaudeSetupBoxOfferTokenCredential(::std::string::String);
    impl ChannelClaudeSetupBoxOfferTokenCredential {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelClaudeSetupBoxOfferTokenCredential {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelClaudeSetupBoxOfferTokenCredential {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelClaudeSetupBoxOfferTokenCredential {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelClaudeSetupBoxOfferTokenCredential {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelClaudeSetupBoxOfferTokenCredential> for ::std::string::String {
        fn from(value: ChannelClaudeSetupBoxOfferTokenCredential) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelClaudeSetupBoxOfferTokenCredential {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 43usize {
                return Err("ChannelClaudeSetupBoxOfferTokenCredential: shorter than 43 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelClaudeSetupBoxOfferTokenCredential {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelClaudeSetupBoxOfferTokenCredential {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelClaudeSetupBoxOfferTokenCredential {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelClaudeSetupBoxOfferType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelClaudeSetupBoxOfferType {
        ClaudeSetupBoxOffer,
    }
    impl ::std::fmt::Display for ChannelClaudeSetupBoxOfferType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ClaudeSetupBoxOffer => f.write_str("ClaudeSetupBoxOffer"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelClaudeSetupBoxOfferType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ClaudeSetupBoxOffer" => Ok(Self::ClaudeSetupBoxOffer),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelClaudeSetupBoxOfferType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelClaudeSetupBoxOfferType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The setup's `claude setup-token` printed the URL where the person signs in.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelClaudeSetupBoxUrl {
        #[serde(rename = "claudeSetupId")]
        pub claude_setup_id: EntityId,
        #[serde(rename = "signInUrl")]
        pub sign_in_url: ::std::string::String,
        #[serde(rename = "type")]
        pub type_: ChannelClaudeSetupBoxUrlType,
        #[serde(rename = "userCode", skip_serializing_if = "::std::option::Option::is_none")]
        pub user_code: ::std::option::Option<ChannelClaudeSetupBoxUrlUserCode>,
    }
    ///`ChannelClaudeSetupBoxUrlType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelClaudeSetupBoxUrlType {
        ClaudeSetupBoxUrl,
    }
    impl ::std::fmt::Display for ChannelClaudeSetupBoxUrlType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ClaudeSetupBoxUrl => f.write_str("ClaudeSetupBoxUrl"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelClaudeSetupBoxUrlType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ClaudeSetupBoxUrl" => Ok(Self::ClaudeSetupBoxUrl),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelClaudeSetupBoxUrlType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelClaudeSetupBoxUrlType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`ChannelClaudeSetupBoxUrlUserCode`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelClaudeSetupBoxUrlUserCode(::std::string::String);
    impl ChannelClaudeSetupBoxUrlUserCode {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelClaudeSetupBoxUrlUserCode {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelClaudeSetupBoxUrlUserCode {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelClaudeSetupBoxUrlUserCode {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelClaudeSetupBoxUrlUserCode {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelClaudeSetupBoxUrlUserCode> for ::std::string::String {
        fn from(value: ChannelClaudeSetupBoxUrlUserCode) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelClaudeSetupBoxUrlUserCode {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 64usize {
                return Err("ChannelClaudeSetupBoxUrlUserCode: longer than 64 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("ChannelClaudeSetupBoxUrlUserCode: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelClaudeSetupBoxUrlUserCode {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelClaudeSetupBoxUrlUserCode {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelClaudeSetupBoxUrlUserCode {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///The WebSocket close code each side closes a connection with. Revoked tells the host the tenant
    ///revoked it: the host stops its boxes, deletes its key and does not reconnect. On every other
    ///code but BadSignature and UnsupportedVersion the host reconnects.
    #[derive(::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(transparent)]
    pub struct ChannelCloseCode(i64);
    impl ::std::ops::Deref for ChannelCloseCode {
        type Target = i64;
        fn deref(&self) -> &i64 {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelCloseCode> for i64 {
        fn from(value: ChannelCloseCode) -> Self {
            value.0
        }
    }
    impl ::std::convert::TryFrom<i64> for ChannelCloseCode {
        type Error = self::error::ConversionError;
        fn try_from(value: i64) -> ::std::result::Result<Self, self::error::ConversionError> {
            if ![4400_i64, 4401_i64, 4403_i64, 4408_i64, 4409_i64, 4426_i64].contains(&value) {
                Err("invalid value".into())
            } else {
                Ok(Self(value))
            }
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelCloseCode {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            Self::try_from(<i64>::deserialize(deserializer)?)
                .map_err(|e| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///Everything the control plane sends on a connection: Challenge, Welcome, Heartbeat, ReleasePublished, FrameRefused, or a sequenced frame.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(untagged)]
    pub enum ChannelControlEnvelope {
        Challenge(ChannelChallenge),
        Welcome(ChannelWelcome),
        Heartbeat(ChannelHeartbeat),
        ReleasePublished(ChannelReleasePublished),
        FrameRefused(ChannelFrameRefused),
        ControlFrame(ChannelControlFrame),
    }
    impl ::std::convert::From<ChannelChallenge> for ChannelControlEnvelope {
        fn from(value: ChannelChallenge) -> Self {
            Self::Challenge(value)
        }
    }
    impl ::std::convert::From<ChannelWelcome> for ChannelControlEnvelope {
        fn from(value: ChannelWelcome) -> Self {
            Self::Welcome(value)
        }
    }
    impl ::std::convert::From<ChannelHeartbeat> for ChannelControlEnvelope {
        fn from(value: ChannelHeartbeat) -> Self {
            Self::Heartbeat(value)
        }
    }
    impl ::std::convert::From<ChannelReleasePublished> for ChannelControlEnvelope {
        fn from(value: ChannelReleasePublished) -> Self {
            Self::ReleasePublished(value)
        }
    }
    impl ::std::convert::From<ChannelFrameRefused> for ChannelControlEnvelope {
        fn from(value: ChannelFrameRefused) -> Self {
            Self::FrameRefused(value)
        }
    }
    impl ::std::convert::From<ChannelControlFrame> for ChannelControlEnvelope {
        fn from(value: ChannelControlFrame) -> Self {
            Self::ControlFrame(value)
        }
    }
    ///One message from the control plane to the host, sequenced per Sequenced.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelControlFrame {
        pub ack: Sequence,
        pub message: ChannelControlMessage,
        pub seq: Sequence,
        #[serde(rename = "type")]
        pub type_: ChannelControlFrameType,
    }
    ///`ChannelControlFrameType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelControlFrameType {
        Frame,
    }
    impl ::std::fmt::Display for ChannelControlFrameType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Frame => f.write_str("Frame"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelControlFrameType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Frame" => Ok(Self::Frame),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelControlFrameType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelControlFrameType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`ChannelControlMessage`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(untagged)]
    pub enum ChannelControlMessage {
        TurnOffer(ChannelTurnOffer),
        TurnWithdrawn(ChannelTurnWithdrawn),
        TurnClaimed(ChannelTurnClaimed),
        SnapshotRequest(ChannelSnapshotRequest),
        SnapshotChunksHeld(ChannelSnapshotChunksHeld),
        SnapshotPackUploads(ChannelSnapshotPackUploads),
        RestoreDownloads(ChannelRestoreDownloads),
        BoxTeardown(ChannelBoxTeardown),
        BoxDiscard(ChannelBoxDiscard),
        ClaudeSetupBoxOffer(ChannelClaudeSetupBoxOffer),
        ClaudeSetupBoxCode(ChannelClaudeSetupBoxCode),
        ClaudeSetupBoxDiscard(ChannelClaudeSetupBoxDiscard),
    }
    impl ::std::convert::From<ChannelTurnOffer> for ChannelControlMessage {
        fn from(value: ChannelTurnOffer) -> Self {
            Self::TurnOffer(value)
        }
    }
    impl ::std::convert::From<ChannelTurnWithdrawn> for ChannelControlMessage {
        fn from(value: ChannelTurnWithdrawn) -> Self {
            Self::TurnWithdrawn(value)
        }
    }
    impl ::std::convert::From<ChannelTurnClaimed> for ChannelControlMessage {
        fn from(value: ChannelTurnClaimed) -> Self {
            Self::TurnClaimed(value)
        }
    }
    impl ::std::convert::From<ChannelSnapshotRequest> for ChannelControlMessage {
        fn from(value: ChannelSnapshotRequest) -> Self {
            Self::SnapshotRequest(value)
        }
    }
    impl ::std::convert::From<ChannelSnapshotChunksHeld> for ChannelControlMessage {
        fn from(value: ChannelSnapshotChunksHeld) -> Self {
            Self::SnapshotChunksHeld(value)
        }
    }
    impl ::std::convert::From<ChannelSnapshotPackUploads> for ChannelControlMessage {
        fn from(value: ChannelSnapshotPackUploads) -> Self {
            Self::SnapshotPackUploads(value)
        }
    }
    impl ::std::convert::From<ChannelRestoreDownloads> for ChannelControlMessage {
        fn from(value: ChannelRestoreDownloads) -> Self {
            Self::RestoreDownloads(value)
        }
    }
    impl ::std::convert::From<ChannelBoxTeardown> for ChannelControlMessage {
        fn from(value: ChannelBoxTeardown) -> Self {
            Self::BoxTeardown(value)
        }
    }
    impl ::std::convert::From<ChannelBoxDiscard> for ChannelControlMessage {
        fn from(value: ChannelBoxDiscard) -> Self {
            Self::BoxDiscard(value)
        }
    }
    impl ::std::convert::From<ChannelClaudeSetupBoxOffer> for ChannelControlMessage {
        fn from(value: ChannelClaudeSetupBoxOffer) -> Self {
            Self::ClaudeSetupBoxOffer(value)
        }
    }
    impl ::std::convert::From<ChannelClaudeSetupBoxCode> for ChannelControlMessage {
        fn from(value: ChannelClaudeSetupBoxCode) -> Self {
            Self::ClaudeSetupBoxCode(value)
        }
    }
    impl ::std::convert::From<ChannelClaudeSetupBoxDiscard> for ChannelControlMessage {
        fn from(value: ChannelClaudeSetupBoxDiscard) -> Self {
            Self::ClaudeSetupBoxDiscard(value)
        }
    }
    ///The dispatch variables for one offer: every member of the persona's secret set, the credential for
    ///the harness's provider under the variable its kind maps to and every other member under its own
    ///name. The control plane decrypts them from the secret set each time it sends or resends a
    ///TurnOffer, keeps no plaintext copy and records the variable names in an append-only handover log;
    ///`credentialHandoverId` names this handover in the supervisor's errors. `expiresAt`, the end of
    ///the turn's credential span (the longer of dispatchGrantTtlSeconds and turnOfferTtlSeconds plus
    ///turnImageFetchBudgetSeconds, from when the offer was sent), is when the supervisor stops handing
    ///the variables to a box and fails the turn DispatchCredentialExpired instead.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelDispatchGrant {
        ///The harness arguments the catalog maps the credential to; they hold no secret. A grant without them gives the guest none.
        #[serde(default, skip_serializing_if = "::std::vec::Vec::is_empty")]
        pub arguments: ::std::vec::Vec<::std::string::String>,
        #[serde(rename = "credentialFile", skip_serializing_if = "::std::option::Option::is_none")]
        pub credential_file: ::std::option::Option<ChannelDispatchGrantCredentialFile>,
        #[serde(rename = "credentialHandoverId")]
        pub credential_handover_id: EntityId,
        #[serde(rename = "expiresAt")]
        pub expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub variables: ::std::vec::Vec<ChannelDispatchVariable>,
    }
    ///A CredentialFile credential: the guest writes `value` to `path` under the harness home, mode 0600, before the harness starts, and deletes it at the end of the turn.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelDispatchGrantCredentialFile {
        pub path: ChannelDispatchGrantCredentialFilePath,
        pub value: ChannelDispatchGrantCredentialFileValue,
    }
    ///`ChannelDispatchGrantCredentialFilePath`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelDispatchGrantCredentialFilePath(::std::string::String);
    impl ChannelDispatchGrantCredentialFilePath {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelDispatchGrantCredentialFilePath {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelDispatchGrantCredentialFilePath {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelDispatchGrantCredentialFilePath {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelDispatchGrantCredentialFilePath {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelDispatchGrantCredentialFilePath> for ::std::string::String {
        fn from(value: ChannelDispatchGrantCredentialFilePath) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelDispatchGrantCredentialFilePath {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelDispatchGrantCredentialFilePath: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelDispatchGrantCredentialFilePath {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelDispatchGrantCredentialFilePath {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelDispatchGrantCredentialFilePath {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelDispatchGrantCredentialFileValue`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelDispatchGrantCredentialFileValue(::std::string::String);
    impl ChannelDispatchGrantCredentialFileValue {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelDispatchGrantCredentialFileValue {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelDispatchGrantCredentialFileValue {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelDispatchGrantCredentialFileValue {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelDispatchGrantCredentialFileValue {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelDispatchGrantCredentialFileValue> for ::std::string::String {
        fn from(value: ChannelDispatchGrantCredentialFileValue) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelDispatchGrantCredentialFileValue {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelDispatchGrantCredentialFileValue: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelDispatchGrantCredentialFileValue {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelDispatchGrantCredentialFileValue {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelDispatchGrantCredentialFileValue {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///One environment variable for one turn: a secret set member's value. It lives in box memory only and is never written to the host's disk.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelDispatchVariable {
        pub name: ChannelDispatchVariableName,
        pub value: ChannelDispatchVariableValue,
    }
    ///`ChannelDispatchVariableName`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelDispatchVariableName(::std::string::String);
    impl ChannelDispatchVariableName {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelDispatchVariableName {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelDispatchVariableName {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelDispatchVariableName {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelDispatchVariableName {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelDispatchVariableName> for ::std::string::String {
        fn from(value: ChannelDispatchVariableName) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelDispatchVariableName {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelDispatchVariableName: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelDispatchVariableName {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelDispatchVariableName {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelDispatchVariableName {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelDispatchVariableValue`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelDispatchVariableValue(::std::string::String);
    impl ChannelDispatchVariableValue {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelDispatchVariableValue {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelDispatchVariableValue {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelDispatchVariableValue {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelDispatchVariableValue {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelDispatchVariableValue> for ::std::string::String {
        fn from(value: ChannelDispatchVariableValue) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelDispatchVariableValue {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelDispatchVariableValue: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelDispatchVariableValue {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelDispatchVariableValue {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelDispatchVariableValue {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///The control plane's answer to a host frame whose message matches no HostMessage. It travels
    ///outside frames, as Heartbeat does. The control plane counts that `seq` as received, so the next
    ///frame follows it without a gap, records nothing for it, and names the mismatch in `reason`. The
    ///host drops the frame from its unacked frames and logs FrameRefused with the reason, so one frame
    ///no control plane reads never holds up the channel. A supervisor that predates this message closes
    ///the connection with ProtocolError on it, and its reconnect resends the frame, which the control
    ///plane drops as a duplicate.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelFrameRefused {
        pub reason: ChannelFrameRefusedReason,
        pub seq: Sequence,
        #[serde(rename = "type")]
        pub type_: ChannelFrameRefusedType,
    }
    ///`ChannelFrameRefusedReason`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelFrameRefusedReason(::std::string::String);
    impl ChannelFrameRefusedReason {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelFrameRefusedReason {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelFrameRefusedReason {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelFrameRefusedReason {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelFrameRefusedReason {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelFrameRefusedReason> for ::std::string::String {
        fn from(value: ChannelFrameRefusedReason) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelFrameRefusedReason {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelFrameRefusedReason: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelFrameRefusedReason {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelFrameRefusedReason {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelFrameRefusedReason {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelFrameRefusedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelFrameRefusedType {
        FrameRefused,
    }
    impl ::std::fmt::Display for ChannelFrameRefusedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::FrameRefused => f.write_str("FrameRefused"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelFrameRefusedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "FrameRefused" => Ok(Self::FrameRefused),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelFrameRefusedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelFrameRefusedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The full guest image of the turn, from the current ReleaseManifest, for the session's harness version
    ///and the architecture the host enrolled with, offered while the release lacks a base image or a
    ///harness layer for them. `imageUrl`, `kernelUrl` and `manifestUrl` are presigned
    ///GETs of the ext4 image, the kernel and the GuestImageManifest document stored under
    ///`imageDigest`, `kernelDigest` and `manifestDigest` in the release bucket, valid until
    ///`downloadExpiresAt`, turnOfferTtlSeconds plus `fetchSeconds` after the send of the offer. A supervisor whose
    ///image cache lacks `imageDigest` sends TurnImageFetching and downloads the three within `fetchSeconds` of
    ///sending it, counting the wait for another image the host is fetching; it fetches one image at a time,
    ///checks each against its digest and only then moves them into the cache, replacing the cached image
    ///of the same harness version; it skips the kernel when the cache holds `kernelDigest`. A download
    ///that fails, misses its digest or names another image in its manifest fails the turn ImageFetchFailed,
    ///one that outlasts `fetchSeconds` fails it ImageFetchTimedOut.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelGuestImageDownload {
        #[serde(rename = "downloadExpiresAt")]
        pub download_expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "fetchSeconds")]
        pub fetch_seconds: ::std::num::NonZeroU32,
        #[serde(rename = "imageDigest")]
        pub image_digest: Sha256Digest,
        #[serde(rename = "imageUrl")]
        pub image_url: ::std::string::String,
        #[serde(rename = "kernelDigest")]
        pub kernel_digest: Sha256Digest,
        #[serde(rename = "kernelUrl")]
        pub kernel_url: ::std::string::String,
        pub kind: ChannelGuestImageDownloadKind,
        #[serde(rename = "manifestDigest")]
        pub manifest_digest: Sha256Digest,
        #[serde(rename = "manifestUrl")]
        pub manifest_url: ::std::string::String,
    }
    ///`ChannelGuestImageDownloadKind`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelGuestImageDownloadKind {
        Full,
    }
    impl ::std::fmt::Display for ChannelGuestImageDownloadKind {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Full => f.write_str("Full"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelGuestImageDownloadKind {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Full" => Ok(Self::Full),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelGuestImageDownloadKind {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelGuestImageDownloadKind {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The harness layer of a layered boot, the current release's ReleaseHarnessLayer for the session's
    ///harness version and the host's architecture. `layerUrl` and `manifestUrl` are presigned GETs of
    ///the squashfs file and the HarnessLayerManifest document stored under `layer.layerDigest` and
    ///`layer.manifestDigest` in the release bucket.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelHarnessLayerDownload {
        pub layer: ReleaseHarnessLayer,
        #[serde(rename = "layerUrl")]
        pub layer_url: ::std::string::String,
        #[serde(rename = "manifestUrl")]
        pub manifest_url: ::std::string::String,
    }
    ///The control plane sends one when it has sent nothing else for its heartbeat interval of 10
    ///seconds. A side that has received nothing for 30 seconds treats the connection as dead and closes
    ///it; the control plane then reads the host Offline.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelHeartbeat {
        #[serde(rename = "sentAt")]
        pub sent_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "type")]
        pub type_: ChannelHeartbeatType,
    }
    ///`ChannelHeartbeatType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelHeartbeatType {
        Heartbeat,
    }
    impl ::std::fmt::Display for ChannelHeartbeatType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Heartbeat => f.write_str("Heartbeat"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelHeartbeatType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Heartbeat" => Ok(Self::Heartbeat),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelHeartbeatType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelHeartbeatType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host's answer to Challenge. `signature` is the base64 Ed25519 signature, by the host key
    ///made at enrolment, over these bytes in order: the ASCII string `tumpel-channel-hello-v1`, one
    ///0x00 byte, the ASCII bytes of the Challenge `nonce`, one 0x00 byte, and the UTF-8 bytes of
    ///`hostId`. The control plane rebuilds those bytes from the nonce it sent and verifies the
    ///signature against the host's stored public key. It answers Welcome, and closes the connection
    ///with BadSignature on a bad signature, Revoked for a revoked host, and UnsupportedVersion for a
    ///protocol version outside ChannelProtocol.Oldest to ChannelProtocol.Version. `boxCapacity` is the host's box slots from
    ///its runtime config and `usage` what it holds as it connects; the control plane keeps both for
    ///the host's tenant before it reads the host Online.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelHello {
        #[serde(rename = "boxCapacity")]
        pub box_capacity: ::std::num::NonZeroU32,
        #[serde(rename = "hostId")]
        pub host_id: EntityId,
        #[serde(rename = "protocolVersion")]
        pub protocol_version: ::std::num::NonZeroU32,
        pub signature: ChannelHelloSignature,
        #[serde(rename = "supervisorVersion")]
        pub supervisor_version: ChannelHelloSupervisorVersion,
        #[serde(rename = "type")]
        pub type_: ChannelHelloType,
        pub usage: HostUsage,
    }
    ///`ChannelHelloSignature`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelHelloSignature(::std::string::String);
    impl ChannelHelloSignature {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelHelloSignature {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelHelloSignature {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelHelloSignature {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelHelloSignature {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelHelloSignature> for ::std::string::String {
        fn from(value: ChannelHelloSignature) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelHelloSignature {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelHelloSignature: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelHelloSignature {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelHelloSignature {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelHelloSignature {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelHelloSupervisorVersion`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelHelloSupervisorVersion(::std::string::String);
    impl ChannelHelloSupervisorVersion {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelHelloSupervisorVersion {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelHelloSupervisorVersion {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelHelloSupervisorVersion {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelHelloSupervisorVersion {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelHelloSupervisorVersion> for ::std::string::String {
        fn from(value: ChannelHelloSupervisorVersion) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelHelloSupervisorVersion {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelHelloSupervisorVersion: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelHelloSupervisorVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelHelloSupervisorVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelHelloSupervisorVersion {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelHelloType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelHelloType {
        Hello,
    }
    impl ::std::fmt::Display for ChannelHelloType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Hello => f.write_str("Hello"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelHelloType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Hello" => Ok(Self::Hello),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelHelloType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelHelloType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Everything the host sends on a connection: Hello, Heartbeat, or a sequenced frame. The host opens
    ///every connection itself, as a WebSocket to /v1/hosts/{hostId}/channel on the control plane's
    ///endpoint (wss for https, ws for http), and the control plane holds at most one per host: a new
    ///connection that reaches Welcome closes the one before it. Each message is one JSON text message.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(untagged)]
    pub enum ChannelHostEnvelope {
        Hello(ChannelHello),
        HostHeartbeat(ChannelHostHeartbeat),
        HostFrame(ChannelHostFrame),
    }
    impl ::std::convert::From<ChannelHello> for ChannelHostEnvelope {
        fn from(value: ChannelHello) -> Self {
            Self::Hello(value)
        }
    }
    impl ::std::convert::From<ChannelHostHeartbeat> for ChannelHostEnvelope {
        fn from(value: ChannelHostHeartbeat) -> Self {
            Self::HostHeartbeat(value)
        }
    }
    impl ::std::convert::From<ChannelHostFrame> for ChannelHostEnvelope {
        fn from(value: ChannelHostFrame) -> Self {
            Self::HostFrame(value)
        }
    }
    ///One message from the host to the control plane, sequenced per Sequenced.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelHostFrame {
        pub ack: Sequence,
        pub message: ChannelHostMessage,
        pub seq: Sequence,
        #[serde(rename = "type")]
        pub type_: ChannelHostFrameType,
    }
    ///`ChannelHostFrameType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelHostFrameType {
        Frame,
    }
    impl ::std::fmt::Display for ChannelHostFrameType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Frame => f.write_str("Frame"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelHostFrameType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Frame" => Ok(Self::Frame),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelHostFrameType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelHostFrameType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host sends one every 10 seconds after Welcome, whatever else it sends, with its usage. The
    ///control plane keeps the last one per host for the host's tenant, which places a new session on
    ///the Online host with the most free box slots, then the most memory available.
    ///`heldSessionIds` names every session the host holds a box for, whether the box runs a turn, waits
    ///warm or still boots, and is empty when it holds none. The host sends every frame queued before it
    ///read the list ahead of the Heartbeat, so the first Heartbeat after Welcome follows the resent
    ///frames. On that Heartbeat the control plane fails each Running turn on the host whose session the
    ///list does not name with BoxLost.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelHostHeartbeat {
        #[serde(rename = "heldSessionIds")]
        pub held_session_ids: ::std::vec::Vec<EntityId>,
        #[serde(rename = "sentAt")]
        pub sent_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "type")]
        pub type_: ChannelHostHeartbeatType,
        pub usage: HostUsage,
    }
    ///`ChannelHostHeartbeatType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelHostHeartbeatType {
        Heartbeat,
    }
    impl ::std::fmt::Display for ChannelHostHeartbeatType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Heartbeat => f.write_str("Heartbeat"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelHostHeartbeatType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Heartbeat" => Ok(Self::Heartbeat),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelHostHeartbeatType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelHostHeartbeatType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`ChannelHostMessage`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(untagged)]
    pub enum ChannelHostMessage {
        TurnImageFetching(ChannelTurnImageFetching),
        TurnClaim(ChannelTurnClaim),
        TurnRepositoryReady(ChannelTurnRepositoryReady),
        TurnLine(ChannelTurnLine),
        TurnComplete(ChannelTurnComplete),
        TurnRepositoryCloneFailed(ChannelTurnRepositoryCloneFailed),
        TurnFailed(ChannelTurnFailed),
        SnapshotChunks(ChannelSnapshotChunks),
        SnapshotPacks(ChannelSnapshotPacks),
        RestoreChunks(ChannelRestoreChunks),
        SnapshotDone(ChannelSnapshotDone),
        SnapshotFailed(ChannelSnapshotFailed),
        BoxGone(ChannelBoxGone),
        BoxTeardownFailed(ChannelBoxTeardownFailed),
        ClaudeSetupBoxUrl(ChannelClaudeSetupBoxUrl),
        ClaudeSetupBoxFailed(ChannelClaudeSetupBoxFailed),
        SupervisorUpdateStep(ChannelSupervisorUpdateStep),
        SupervisorUpdateFailed(ChannelSupervisorUpdateFailed),
        TelemetryBatch(ChannelTelemetryBatch),
    }
    impl ::std::convert::From<ChannelTurnImageFetching> for ChannelHostMessage {
        fn from(value: ChannelTurnImageFetching) -> Self {
            Self::TurnImageFetching(value)
        }
    }
    impl ::std::convert::From<ChannelTurnClaim> for ChannelHostMessage {
        fn from(value: ChannelTurnClaim) -> Self {
            Self::TurnClaim(value)
        }
    }
    impl ::std::convert::From<ChannelTurnRepositoryReady> for ChannelHostMessage {
        fn from(value: ChannelTurnRepositoryReady) -> Self {
            Self::TurnRepositoryReady(value)
        }
    }
    impl ::std::convert::From<ChannelTurnLine> for ChannelHostMessage {
        fn from(value: ChannelTurnLine) -> Self {
            Self::TurnLine(value)
        }
    }
    impl ::std::convert::From<ChannelTurnComplete> for ChannelHostMessage {
        fn from(value: ChannelTurnComplete) -> Self {
            Self::TurnComplete(value)
        }
    }
    impl ::std::convert::From<ChannelTurnRepositoryCloneFailed> for ChannelHostMessage {
        fn from(value: ChannelTurnRepositoryCloneFailed) -> Self {
            Self::TurnRepositoryCloneFailed(value)
        }
    }
    impl ::std::convert::From<ChannelTurnFailed> for ChannelHostMessage {
        fn from(value: ChannelTurnFailed) -> Self {
            Self::TurnFailed(value)
        }
    }
    impl ::std::convert::From<ChannelSnapshotChunks> for ChannelHostMessage {
        fn from(value: ChannelSnapshotChunks) -> Self {
            Self::SnapshotChunks(value)
        }
    }
    impl ::std::convert::From<ChannelSnapshotPacks> for ChannelHostMessage {
        fn from(value: ChannelSnapshotPacks) -> Self {
            Self::SnapshotPacks(value)
        }
    }
    impl ::std::convert::From<ChannelRestoreChunks> for ChannelHostMessage {
        fn from(value: ChannelRestoreChunks) -> Self {
            Self::RestoreChunks(value)
        }
    }
    impl ::std::convert::From<ChannelSnapshotDone> for ChannelHostMessage {
        fn from(value: ChannelSnapshotDone) -> Self {
            Self::SnapshotDone(value)
        }
    }
    impl ::std::convert::From<ChannelSnapshotFailed> for ChannelHostMessage {
        fn from(value: ChannelSnapshotFailed) -> Self {
            Self::SnapshotFailed(value)
        }
    }
    impl ::std::convert::From<ChannelBoxGone> for ChannelHostMessage {
        fn from(value: ChannelBoxGone) -> Self {
            Self::BoxGone(value)
        }
    }
    impl ::std::convert::From<ChannelBoxTeardownFailed> for ChannelHostMessage {
        fn from(value: ChannelBoxTeardownFailed) -> Self {
            Self::BoxTeardownFailed(value)
        }
    }
    impl ::std::convert::From<ChannelClaudeSetupBoxUrl> for ChannelHostMessage {
        fn from(value: ChannelClaudeSetupBoxUrl) -> Self {
            Self::ClaudeSetupBoxUrl(value)
        }
    }
    impl ::std::convert::From<ChannelClaudeSetupBoxFailed> for ChannelHostMessage {
        fn from(value: ChannelClaudeSetupBoxFailed) -> Self {
            Self::ClaudeSetupBoxFailed(value)
        }
    }
    impl ::std::convert::From<ChannelSupervisorUpdateStep> for ChannelHostMessage {
        fn from(value: ChannelSupervisorUpdateStep) -> Self {
            Self::SupervisorUpdateStep(value)
        }
    }
    impl ::std::convert::From<ChannelSupervisorUpdateFailed> for ChannelHostMessage {
        fn from(value: ChannelSupervisorUpdateFailed) -> Self {
            Self::SupervisorUpdateFailed(value)
        }
    }
    impl ::std::convert::From<ChannelTelemetryBatch> for ChannelHostMessage {
        fn from(value: ChannelTelemetryBatch) -> Self {
            Self::TelemetryBatch(value)
        }
    }
    ///The layered boot of the turn, offered when the current release carries a base image for the
    ///host's architecture and a harness layer for the session's harness version on it. The box boots
    ///from the base, the guest drive of the host's supervisor and the layer. The URLs are valid until
    ///`downloadExpiresAt`, turnOfferTtlSeconds plus `fetchSeconds` after the send of the offer. A supervisor whose
    ///cache lacks the base or the layer sends TurnImageFetching naming the first part it lacks, then
    ///fetches base, kernel and layer within one `fetchSeconds` of sending it, counting the wait for
    ///another fetch on the host, and checks each against its digest before it moves it into the cache. A
    ///download that fails, misses its digest or names another part in its manifest fails the turn
    ///ImageFetchFailed, one that outlasts `fetchSeconds` fails it ImageFetchTimedOut. The host keeps the
    ///base and the layer in its cache while a box runs on them.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelLayeredImageDownload {
        pub base: ChannelBaseImageDownload,
        #[serde(rename = "downloadExpiresAt")]
        pub download_expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "fetchSeconds")]
        pub fetch_seconds: ::std::num::NonZeroU32,
        pub kind: ChannelLayeredImageDownloadKind,
        pub layer: ChannelHarnessLayerDownload,
    }
    ///`ChannelLayeredImageDownloadKind`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelLayeredImageDownloadKind {
        Layered,
    }
    impl ::std::fmt::Display for ChannelLayeredImageDownloadKind {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Layered => f.write_str("Layered"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelLayeredImageDownloadKind {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Layered" => Ok(Self::Layered),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelLayeredImageDownloadKind {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelLayeredImageDownloadKind {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///One pack: `packDigest` is the SHA-256 of its `sizeBytes` bytes.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelPack {
        #[serde(rename = "packDigest")]
        pub pack_digest: Sha256Digest,
        #[serde(rename = "sizeBytes")]
        pub size_bytes: ::std::num::NonZeroU64,
    }
    ///One pack object stored under `<tenantId>/packs/<packDigest>`, `sizeBytes` long, and `url` a
    ///presigned URL of that object alone.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelPackUrl {
        #[serde(rename = "packDigest")]
        pub pack_digest: Sha256Digest,
        #[serde(rename = "sizeBytes")]
        pub size_bytes: ::std::num::NonZeroU64,
        pub url: ::std::string::String,
    }
    ///One file of the session's persona. `downloadUrl` is a presigned GET of the blob stored under
    ///`digest`, valid until `downloadExpiresAt`, the DispatchGrant's expiresAt. The supervisor
    ///checks the bytes against `digest` and keeps them in its cache, so a digest it already holds is
    ///not fetched again.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelPersonaFileDownload {
        pub digest: Sha256Digest,
        #[serde(rename = "downloadExpiresAt")]
        pub download_expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "downloadUrl")]
        pub download_url: ::std::string::String,
        pub path: PersonaFilePath,
        #[serde(rename = "sizeBytes")]
        pub size_bytes: PersonaFileSize,
    }
    ///The control plane sends one to every Online host when the release bucket stores a new current
    ///release, `releaseVersion` naming it. It travels outside frames, as Heartbeat does, so it is never
    ///resent: a host that misses it reads the release at its next Welcome. The host reads
    ///GET /v1/releases/current and updates its supervisor when the release names another binary. A
    ///supervisor that predates this message closes the connection with ProtocolError on it, and the
    ///Welcome of its reconnect reads the release.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelReleasePublished {
        #[serde(rename = "releaseVersion")]
        pub release_version: ChannelReleasePublishedReleaseVersion,
        #[serde(rename = "type")]
        pub type_: ChannelReleasePublishedType,
    }
    ///`ChannelReleasePublishedReleaseVersion`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelReleasePublishedReleaseVersion(::std::string::String);
    impl ChannelReleasePublishedReleaseVersion {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelReleasePublishedReleaseVersion {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelReleasePublishedReleaseVersion {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelReleasePublishedReleaseVersion {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelReleasePublishedReleaseVersion {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelReleasePublishedReleaseVersion> for ::std::string::String {
        fn from(value: ChannelReleasePublishedReleaseVersion) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelReleasePublishedReleaseVersion {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelReleasePublishedReleaseVersion: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelReleasePublishedReleaseVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelReleasePublishedReleaseVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelReleasePublishedReleaseVersion {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelReleasePublishedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelReleasePublishedType {
        ReleasePublished,
    }
    impl ::std::fmt::Display for ChannelReleasePublishedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ReleasePublished => f.write_str("ReleasePublished"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelReleasePublishedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ReleasePublished" => Ok(Self::ReleasePublished),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelReleasePublishedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelReleasePublishedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Part `part` of the chunks a box that boots cold needs for turn `turnId` and lacks in the host's
    ///chunk cache, each at the placement its manifest or root names, at most
    ///ChunkExchange.DigestsPerPart of them, grouped by pack. The host sends each next part once the
    ///answer to the one before arrived, and starts the downloads of each part as its answer arrives.
    ///The control plane answers RestoreDownloads.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelRestoreChunks {
        pub chunks: ::std::vec::Vec<ChannelChunkPlacement>,
        pub part: ::std::num::NonZeroU32,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelRestoreChunksType,
    }
    ///`ChannelRestoreChunksType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelRestoreChunksType {
        RestoreChunks,
    }
    impl ::std::fmt::Display for ChannelRestoreChunksType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::RestoreChunks => f.write_str("RestoreChunks"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelRestoreChunksType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "RestoreChunks" => Ok(Self::RestoreChunks),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelRestoreChunksType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelRestoreChunksType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The answer to RestoreChunks part `part`: a presigned GET for each pack that holds chunks of that
    ///part, valid until `downloadExpiresAt`, the DispatchGrant's expiresAt. A pack is left out when
    ///any chunk asked in it is no chunk of the session at that placement, and the host fails the turn
    ///SnapshotUnreadable.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelRestoreDownloads {
        #[serde(rename = "downloadExpiresAt")]
        pub download_expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub packs: ::std::vec::Vec<ChannelPackUrl>,
        pub part: ::std::num::NonZeroU32,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelRestoreDownloadsType,
    }
    ///`ChannelRestoreDownloadsType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelRestoreDownloadsType {
        RestoreDownloads,
    }
    impl ::std::fmt::Display for ChannelRestoreDownloadsType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::RestoreDownloads => f.write_str("RestoreDownloads"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelRestoreDownloadsType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "RestoreDownloads" => Ok(Self::RestoreDownloads),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelRestoreDownloadsType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelRestoreDownloadsType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Each direction of a host's channel numbers its frames from 1 in `seq`, and the count survives
    ///reconnects and restarts. `ack` is the highest `seq` the sender has received from the other side
    ///with no gap before it, 0 before the first one; it advances only with the sender's next frame. A
    ///receiver drops a frame whose `seq` is at or below the last one it accepted, and treats a gap as
    ///a protocol error that closes the connection. After Welcome each side resends, in order, every
    ///frame the other side has not acked, and the receiver drops the duplicates. The control plane
    ///keeps both counters and its unacked frames in durable storage. The supervisor writes its
    ///counters and unacked frames to disk before it sends a frame; when it starts without that state
    ///it does not dial, and exits with failure ChannelStateLost, and the host is enrolled again.
    ///Challenge, Hello, Welcome and Heartbeat belong to one connection and travel outside frames,
    ///with no `seq` or `ack`. Each side ignores fields it does not know.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSequenced {
        pub ack: Sequence,
        pub seq: Sequence,
    }
    ///Part `part` of the chunk digests the files of a snapshot hold that the box's previous snapshot
    ///did not, at most ChunkExchange.DigestsPerPart of them. The host sends part 1 once its files are
    ///cut, and each next part once the answer to the one before arrived. The control plane answers
    ///SnapshotChunksHeld and counts each digest as referenced by the session.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotChunks {
        pub digests: ::std::vec::Vec<Sha256Digest>,
        pub part: ::std::num::NonZeroU32,
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelSnapshotChunksType,
    }
    ///The answer to SnapshotChunks part `part`: where the tenant stores each digest of that part it
    ///holds already. A digest left out is stored in no pack, and the host packs and uploads it.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotChunksHeld {
        pub held: ::std::vec::Vec<ChannelChunkPlacement>,
        pub part: ::std::num::NonZeroU32,
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelSnapshotChunksHeldType,
    }
    ///`ChannelSnapshotChunksHeldType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotChunksHeldType {
        SnapshotChunksHeld,
    }
    impl ::std::fmt::Display for ChannelSnapshotChunksHeldType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SnapshotChunksHeld => f.write_str("SnapshotChunksHeld"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotChunksHeldType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SnapshotChunksHeld" => Ok(Self::SnapshotChunksHeld),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotChunksHeldType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotChunksHeldType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`ChannelSnapshotChunksType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotChunksType {
        SnapshotChunks,
    }
    impl ::std::fmt::Display for ChannelSnapshotChunksType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SnapshotChunks => f.write_str("SnapshotChunks"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotChunksType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SnapshotChunks" => Ok(Self::SnapshotChunks),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotChunksType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotChunksType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host stored the snapshot's packs and root. `uploadedBytes` counts the bytes it uploaded: the packs the tenant lacked, plus the root.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotDone {
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelSnapshotDoneType,
        #[serde(rename = "uploadedBytes")]
        pub uploaded_bytes: i64,
    }
    ///`ChannelSnapshotDoneType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotDoneType {
        SnapshotDone,
    }
    impl ::std::fmt::Display for ChannelSnapshotDoneType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SnapshotDone => f.write_str("SnapshotDone"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotDoneType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SnapshotDone" => Ok(Self::SnapshotDone),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotDoneType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotDoneType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///One stored snapshot of a session, for a box that boots cold. `downloadUrl` is a presigned GET of
    ///the SnapshotRoot under `storageKey` alone, valid until `downloadExpiresAt`, the end of the turn's
    ///credential span, the DispatchGrant's expiresAt.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotDownload {
        #[serde(rename = "downloadExpiresAt")]
        pub download_expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "downloadUrl")]
        pub download_url: ::std::string::String,
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "snapshotSeq")]
        pub snapshot_seq: Sequence,
        #[serde(rename = "storageKey")]
        pub storage_key: StorageKey,
    }
    ///The host could not store the snapshot. `detail` states what failed and what fixes it.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotFailed {
        pub detail: ::std::string::String,
        #[serde(rename = "failedAt")]
        pub failed_at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub reason: ChannelSnapshotFailureReason,
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelSnapshotFailedType,
    }
    ///`ChannelSnapshotFailedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotFailedType {
        SnapshotFailed,
    }
    impl ::std::fmt::Display for ChannelSnapshotFailedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SnapshotFailed => f.write_str("SnapshotFailed"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotFailedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SnapshotFailed" => Ok(Self::SnapshotFailed),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Why the host could not store a snapshot.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotFailureReason {
        BoxNotFound,
        UpperDirectoryUnreadable,
        UploadExpired,
        UploadRejected,
        SnapshotTimedOut,
        NotAnswered,
    }
    impl ::std::fmt::Display for ChannelSnapshotFailureReason {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::BoxNotFound => f.write_str("BoxNotFound"),
                Self::UpperDirectoryUnreadable => f.write_str("UpperDirectoryUnreadable"),
                Self::UploadExpired => f.write_str("UploadExpired"),
                Self::UploadRejected => f.write_str("UploadRejected"),
                Self::SnapshotTimedOut => f.write_str("SnapshotTimedOut"),
                Self::NotAnswered => f.write_str("NotAnswered"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotFailureReason {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "BoxNotFound" => Ok(Self::BoxNotFound),
                "UpperDirectoryUnreadable" => Ok(Self::UpperDirectoryUnreadable),
                "UploadExpired" => Ok(Self::UploadExpired),
                "UploadRejected" => Ok(Self::UploadRejected),
                "SnapshotTimedOut" => Ok(Self::SnapshotTimedOut),
                "NotAnswered" => Ok(Self::NotAnswered),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The answer to SnapshotPacks part `part`: a presigned PUT for each pack of that part the tenant
    ///holds no object for, valid until `uploadExpiresAt`. Each URL signs the pack's SHA-256 as the
    ///x-amz-checksum-sha256 header, so the host sends that header and object storage refuses bytes that
    ///do not hash to the key. A pack left out is stored already.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotPackUploads {
        pub part: ::std::num::NonZeroU32,
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelSnapshotPackUploadsType,
        #[serde(rename = "uploadExpiresAt")]
        pub upload_expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub uploads: ::std::vec::Vec<ChannelPackUrl>,
    }
    ///`ChannelSnapshotPackUploadsType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotPackUploadsType {
        SnapshotPackUploads,
    }
    impl ::std::fmt::Display for ChannelSnapshotPackUploadsType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SnapshotPackUploads => f.write_str("SnapshotPackUploads"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotPackUploadsType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SnapshotPackUploads" => Ok(Self::SnapshotPackUploads),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotPackUploadsType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotPackUploadsType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Part `part` of the chunks a snapshot packed: where each chunk lies, at most
    ///ChunkExchange.DigestsPerPart of them, and the size of each pack they lie in. A pack whose chunks
    ///run past one part is listed again in the next. The host sends part 1 once its packs are written,
    ///and each next part once the answer to the one before arrived. The control plane keeps the
    ///placements until SnapshotDone, counts each digest as referenced by the session, and answers
    ///SnapshotPackUploads.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotPacks {
        pub chunks: ::std::vec::Vec<ChannelChunkPlacement>,
        pub packs: ::std::vec::Vec<ChannelPack>,
        pub part: ::std::num::NonZeroU32,
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelSnapshotPacksType,
    }
    ///`ChannelSnapshotPacksType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotPacksType {
        SnapshotPacks,
    }
    impl ::std::fmt::Display for ChannelSnapshotPacksType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SnapshotPacks => f.write_str("SnapshotPacks"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotPacksType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SnapshotPacks" => Ok(Self::SnapshotPacks),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotPacksType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotPacksType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Asks the host to store the upper directory of a box as a SnapshotRoot under `storageKey`. The
    ///host sends the chunk digests its files hold that the box's previous snapshot did not in
    ///SnapshotChunks parts, packs the ones the tenant lacks together with the chunks of its encoded
    ///SnapshotManifest, sends their placements in SnapshotPacks parts, uploads the packs each
    ///SnapshotPackUploads names, then PUTs the root to `uploadUrl`, a presigned PUT of `storageKey`
    ///alone, and answers SnapshotDone. Every URL expires at `uploadExpiresAt`, the snapshot deadline,
    ///after which the control plane records the snapshot failed NotAnswered.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSnapshotRequest {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "sessionId")]
        pub session_id: EntityId,
        #[serde(rename = "snapshotId")]
        pub snapshot_id: EntityId,
        #[serde(rename = "snapshotSeq")]
        pub snapshot_seq: Sequence,
        #[serde(rename = "storageKey")]
        pub storage_key: StorageKey,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelSnapshotRequestType,
        #[serde(rename = "uploadExpiresAt")]
        pub upload_expires_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "uploadUrl")]
        pub upload_url: ::std::string::String,
    }
    ///`ChannelSnapshotRequestType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSnapshotRequestType {
        SnapshotRequest,
    }
    impl ::std::fmt::Display for ChannelSnapshotRequestType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SnapshotRequest => f.write_str("SnapshotRequest"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSnapshotRequestType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SnapshotRequest" => Ok(Self::SnapshotRequest),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSnapshotRequestType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSnapshotRequestType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///A HostFrame as channel.json keeps it until the control plane acks it. The message stays as the
    ///supervisor wrote it, so a supervisor of another version loads it whatever message kinds it reads
    ///and resends it unchanged; a message no control plane reads is answered with FrameRefused.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelStoredHostFrame {
        pub ack: Sequence,
        pub message: ::serde_json::Value,
        pub seq: Sequence,
        #[serde(rename = "type")]
        pub type_: ChannelStoredHostFrameType,
    }
    ///`ChannelStoredHostFrameType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelStoredHostFrameType {
        Frame,
    }
    impl ::std::fmt::Display for ChannelStoredHostFrameType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Frame => f.write_str("Frame"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelStoredHostFrameType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Frame" => Ok(Self::Frame),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelStoredHostFrameType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelStoredHostFrameType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host's supervisor update stopped. `detail` states what failed and what fixes it.
    ///`outputTail` holds the last lines the candidate printed in its dry run, token-shaped runs
    ///hidden, and is empty for every other reason.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSupervisorUpdateFailed {
        pub detail: ::std::string::String,
        #[serde(rename = "failedAt")]
        pub failed_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "fromSha256")]
        pub from_sha256: Sha256Digest,
        #[serde(rename = "outputTail")]
        pub output_tail: ::std::vec::Vec<::std::string::String>,
        pub reason: SupervisorUpdateFailureReason,
        #[serde(rename = "toSha256")]
        pub to_sha256: Sha256Digest,
        #[serde(rename = "type")]
        pub type_: ChannelSupervisorUpdateFailedType,
    }
    ///`ChannelSupervisorUpdateFailedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSupervisorUpdateFailedType {
        SupervisorUpdateFailed,
    }
    impl ::std::fmt::Display for ChannelSupervisorUpdateFailedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SupervisorUpdateFailed => f.write_str("SupervisorUpdateFailed"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSupervisorUpdateFailedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SupervisorUpdateFailed" => Ok(Self::SupervisorUpdateFailed),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSupervisorUpdateFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSupervisorUpdateFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host's supervisor update from the binary `fromSha256` to `toSha256` entered `phase`. The new
    ///binary sends Online once it reaches Welcome after the swap.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelSupervisorUpdateStep {
        pub at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "boxesRunning")]
        pub boxes_running: i32,
        #[serde(rename = "fromSha256")]
        pub from_sha256: Sha256Digest,
        pub phase: SupervisorUpdatePhase,
        #[serde(rename = "releaseVersion")]
        pub release_version: ChannelSupervisorUpdateStepReleaseVersion,
        #[serde(rename = "toSha256")]
        pub to_sha256: Sha256Digest,
        #[serde(rename = "type")]
        pub type_: ChannelSupervisorUpdateStepType,
    }
    ///`ChannelSupervisorUpdateStepReleaseVersion`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelSupervisorUpdateStepReleaseVersion(::std::string::String);
    impl ChannelSupervisorUpdateStepReleaseVersion {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelSupervisorUpdateStepReleaseVersion {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelSupervisorUpdateStepReleaseVersion {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelSupervisorUpdateStepReleaseVersion {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelSupervisorUpdateStepReleaseVersion {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelSupervisorUpdateStepReleaseVersion> for ::std::string::String {
        fn from(value: ChannelSupervisorUpdateStepReleaseVersion) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelSupervisorUpdateStepReleaseVersion {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelSupervisorUpdateStepReleaseVersion: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSupervisorUpdateStepReleaseVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSupervisorUpdateStepReleaseVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelSupervisorUpdateStepReleaseVersion {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelSupervisorUpdateStepType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelSupervisorUpdateStepType {
        SupervisorUpdateStep,
    }
    impl ::std::fmt::Display for ChannelSupervisorUpdateStepType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SupervisorUpdateStep => f.write_str("SupervisorUpdateStep"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelSupervisorUpdateStepType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SupervisorUpdateStep" => Ok(Self::SupervisorUpdateStep),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelSupervisorUpdateStepType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelSupervisorUpdateStepType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Metric points the supervisor collected at its lifecycle edges and from its host sampler, sent
    ///while the channel is Welcomed. The control plane overwrites each point's `hostId` dimension with
    ///the host that signed the connection, stamps each turn.cost and turn.tokens point with the
    ///personaId, secretSetId, provider and costBasis of the turn as it offered it, drops a turn.cost
    ///point whose costBasis is NotReported, and writes the batch to the tenant's metrics store. A batch
    ///the store refuses is logged as TelemetryRejected and still acked. The control plane refuses this
    ///message on a connection that speaks a protocol version below 19.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTelemetryBatch {
        pub instruments: ::std::vec::Vec<MetricInstrument>,
        pub samples: ::std::vec::Vec<SamplePoint>,
        pub turns: ::std::vec::Vec<TurnPoint>,
        #[serde(rename = "type")]
        pub type_: ChannelTelemetryBatchType,
    }
    ///`ChannelTelemetryBatchType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTelemetryBatchType {
        TelemetryBatch,
    }
    impl ::std::fmt::Display for ChannelTelemetryBatchType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TelemetryBatch => f.write_str("TelemetryBatch"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTelemetryBatchType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TelemetryBatch" => Ok(Self::TelemetryBatch),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTelemetryBatchType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTelemetryBatchType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host accepts the offered turn. It sends this at once, before it fetches the image, restores the
    ///snapshot or boots the box; those keep their own budgets and failures. The control plane answers TurnClaimed
    ///and the turn reads Running, or answers TurnWithdrawn when the turn already left Offered. The host
    ///hands the prompt to the harness only once TurnClaimed arrived and the box is ready. A host that
    ///gives up waiting for the answer hands nothing and fails the turn NotClaimed, and the control plane
    ///offers the turn again. So a turn is either claimed and its result reaches the control plane, or
    ///refused before the harness starts.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnClaim {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnClaimType,
    }
    ///`ChannelTurnClaimType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnClaimType {
        TurnClaim,
    }
    impl ::std::fmt::Display for ChannelTurnClaimType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnClaim => f.write_str("TurnClaim"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnClaimType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnClaim" => Ok(Self::TurnClaim),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnClaimType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnClaimType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The control plane's answer to a TurnClaim for a turn that was still Offered; the turn now reads Running, and the host hands its prompt to the harness once the box is ready.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnClaimed {
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnClaimedType,
    }
    ///`ChannelTurnClaimedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnClaimedType {
        TurnClaimed,
    }
    impl ::std::fmt::Display for ChannelTurnClaimedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnClaimed => f.write_str("TurnClaimed"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnClaimedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnClaimed" => Ok(Self::TurnClaimed),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnClaimedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnClaimedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The harness finished the turn. `lastLineSeq` is the turn's final line; the control plane holds every line up to it before the turn reads Completed.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnComplete {
        #[serde(rename = "completedAt")]
        pub completed_at: ::chrono::DateTime<::chrono::FixedOffset>,
        ///The turn's credential file as the harness rewrote it; the control plane stores it in place of the secret set's CredentialFile member.
        #[serde(rename = "credentialFile", skip_serializing_if = "::std::option::Option::is_none")]
        pub credential_file: ::std::option::Option<ChannelTurnCompleteCredentialFile>,
        #[serde(rename = "lastLineSeq")]
        pub last_line_seq: Sequence,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnCompleteType,
    }
    ///The turn's credential file as the harness rewrote it; the control plane stores it in place of the secret set's CredentialFile member.
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelTurnCompleteCredentialFile(::std::string::String);
    impl ChannelTurnCompleteCredentialFile {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelTurnCompleteCredentialFile {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelTurnCompleteCredentialFile {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelTurnCompleteCredentialFile {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelTurnCompleteCredentialFile {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelTurnCompleteCredentialFile> for ::std::string::String {
        fn from(value: ChannelTurnCompleteCredentialFile) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelTurnCompleteCredentialFile {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelTurnCompleteCredentialFile: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnCompleteCredentialFile {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnCompleteCredentialFile {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelTurnCompleteCredentialFile {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelTurnCompleteType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnCompleteType {
        TurnComplete,
    }
    impl ::std::fmt::Display for ChannelTurnCompleteType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnComplete => f.write_str("TurnComplete"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnCompleteType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnComplete" => Ok(Self::TurnComplete),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnCompleteType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnCompleteType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`ChannelTurnFailed`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnFailed {
        ///The turn's credential file as the harness rewrote it; the control plane stores it in place of the secret set's CredentialFile member.
        #[serde(rename = "credentialFile", skip_serializing_if = "::std::option::Option::is_none")]
        pub credential_file: ::std::option::Option<ChannelTurnFailedCredentialFile>,
        pub detail: ::std::string::String,
        #[serde(rename = "failedAt")]
        pub failed_at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub reason: TurnFailureReason,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnFailedType,
    }
    ///The turn's credential file as the harness rewrote it; the control plane stores it in place of the secret set's CredentialFile member.
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelTurnFailedCredentialFile(::std::string::String);
    impl ChannelTurnFailedCredentialFile {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelTurnFailedCredentialFile {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelTurnFailedCredentialFile {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelTurnFailedCredentialFile {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelTurnFailedCredentialFile {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelTurnFailedCredentialFile> for ::std::string::String {
        fn from(value: ChannelTurnFailedCredentialFile) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelTurnFailedCredentialFile {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelTurnFailedCredentialFile: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnFailedCredentialFile {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnFailedCredentialFile {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelTurnFailedCredentialFile {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelTurnFailedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnFailedType {
        TurnFailed,
    }
    impl ::std::fmt::Display for ChannelTurnFailedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnFailed => f.write_str("TurnFailed"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnFailedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnFailed" => Ok(Self::TurnFailed),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The host's cache lacks part of the offer's image and the host has started to download it: `imageDigest` names
    ///the full image, or the base image or harness layer of a layered boot, whichever it lacks first.
    ///It follows the TurnClaim; the host fails the turn ImageFetchTimedOut when the fetch outlasts the
    ///offer's `image.fetchSeconds`.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnImageFetching {
        #[serde(rename = "imageDigest")]
        pub image_digest: Sha256Digest,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnImageFetchingType,
    }
    ///`ChannelTurnImageFetchingType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnImageFetchingType {
        TurnImageFetching,
    }
    impl ::std::fmt::Display for ChannelTurnImageFetchingType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnImageFetching => f.write_str("TurnImageFetching"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnImageFetchingType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnImageFetching" => Ok(Self::TurnImageFetching),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnImageFetchingType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnImageFetchingType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///One harness-native JSONL line. `lineSeq` continues the session's line count, so lines of a turn arrive in `lineSeq` order with no gap.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnLine {
        #[serde(rename = "lineSeq")]
        pub line_seq: Sequence,
        pub text: ::std::string::String,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnLineType,
    }
    ///`ChannelTurnLineType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnLineType {
        TurnLine,
    }
    impl ::std::fmt::Display for ChannelTurnLineType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnLine => f.write_str("TurnLine"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnLineType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnLine" => Ok(Self::TurnLine),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnLineType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnLineType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The control plane offers a turn to the host. The host answers TurnClaim, or TurnFailed when it
    ///cannot run it. `lastLineSeq` is the session's last transcript line, so the box numbers the turn's
    ///first line `lastLineSeq` + 1. `snapshots` holds the session's latest stored snapshot, which a box
    ///that boots cold restores from; it is empty for a session with none. `personaFiles` is the persona's file set as it stands when the offer is sent. `gitAuthorName` and
    ///`gitAuthorEmail` are the git identity the box commits as: the bot of the stage's GitHub App when the tenant
    ///installed it, else the GitHub user of the secret set's GITHUB_TOKEN, with its noreply address. `image` is the guest image
    ///the box boots. A resend of the offer keeps its `seq` and carries a new `credential`, `lastLineSeq`,
    ///`snapshots`, `personaFiles`, `image` and git identity.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnOffer {
        #[serde(rename = "boxId")]
        pub box_id: EntityId,
        ///The memory in MiB the box boots with: the persona's boxMemoryMib, or BoxMemoryLimit.DefaultMib. A box
        ///that is already warm keeps the memory it booted with. A supervisor given an offer without it boots
        ///the box with memoryMib of its runtime config.
        #[serde(rename = "boxMemoryMib", skip_serializing_if = "::std::option::Option::is_none")]
        pub box_memory_mib: ::std::option::Option<i32>,
        pub credential: ChannelDispatchGrant,
        #[serde(rename = "gitAuthorEmail")]
        pub git_author_email: EmailAddress,
        #[serde(rename = "gitAuthorName")]
        pub git_author_name: DisplayName,
        pub harness: Harness,
        #[serde(rename = "harnessVersion")]
        pub harness_version: ChannelTurnOfferHarnessVersion,
        pub image: ChannelBootImage,
        #[serde(rename = "lastLineSeq")]
        pub last_line_seq: Sequence,
        pub model: ModelName,
        #[serde(rename = "personaFiles")]
        pub persona_files: ::std::vec::Vec<ChannelPersonaFileDownload>,
        ///Set when the turn builds a prebuild: the box clones the repository at this commit and runs the
        ///repository's setup step, /opt/tumpel/prebuild.mjs run, in place of the harness, its output lines
        ///being the turn's lines. The credential then holds only a GITHUB_TOKEN that reads the
        ///repository's contents, and the snapshot the control plane asks for after the turn is the
        ///prebuild's layer.
        #[serde(rename = "prebuildCommitSha", skip_serializing_if = "::std::option::Option::is_none")]
        pub prebuild_commit_sha: ::std::option::Option<ChannelTurnOfferPrebuildCommitSha>,
        pub prompt: Prompt,
        pub repository: RepositoryUrl,
        #[serde(rename = "sessionId")]
        pub session_id: EntityId,
        pub snapshots: ::std::vec::Vec<ChannelSnapshotDownload>,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnOfferType,
    }
    ///`ChannelTurnOfferHarnessVersion`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelTurnOfferHarnessVersion(::std::string::String);
    impl ChannelTurnOfferHarnessVersion {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelTurnOfferHarnessVersion {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelTurnOfferHarnessVersion {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelTurnOfferHarnessVersion {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelTurnOfferHarnessVersion {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelTurnOfferHarnessVersion> for ::std::string::String {
        fn from(value: ChannelTurnOfferHarnessVersion) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelTurnOfferHarnessVersion {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("ChannelTurnOfferHarnessVersion: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnOfferHarnessVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnOfferHarnessVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelTurnOfferHarnessVersion {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///Set when the turn builds a prebuild: the box clones the repository at this commit and runs the
    ///repository's setup step, /opt/tumpel/prebuild.mjs run, in place of the harness, its output lines
    ///being the turn's lines. The credential then holds only a GITHUB_TOKEN that reads the
    ///repository's contents, and the snapshot the control plane asks for after the turn is the
    ///prebuild's layer.
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ChannelTurnOfferPrebuildCommitSha(::std::string::String);
    impl ChannelTurnOfferPrebuildCommitSha {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ChannelTurnOfferPrebuildCommitSha {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ChannelTurnOfferPrebuildCommitSha {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ChannelTurnOfferPrebuildCommitSha {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ChannelTurnOfferPrebuildCommitSha {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ChannelTurnOfferPrebuildCommitSha> for ::std::string::String {
        fn from(value: ChannelTurnOfferPrebuildCommitSha) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ChannelTurnOfferPrebuildCommitSha {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            static PATTERN: ::std::sync::LazyLock<::regress::Regex> =
                ::std::sync::LazyLock::new(|| ::regress::Regex::new("^[0-9a-f]{40}$").unwrap());
            if PATTERN.find(value).is_none() {
                return Err("ChannelTurnOfferPrebuildCommitSha: doesn't match pattern \"^[0-9a-f]{40}$\"".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnOfferPrebuildCommitSha {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnOfferPrebuildCommitSha {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ChannelTurnOfferPrebuildCommitSha {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ChannelTurnOfferType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnOfferType {
        TurnOffer,
    }
    impl ::std::fmt::Display for ChannelTurnOfferType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnOffer => f.write_str("TurnOffer"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnOfferType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnOffer" => Ok(Self::TurnOffer),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnOfferType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnOfferType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The box could not clone the session's repository; the turn fails RepositoryCloneFailed. `detail` carries what git reported.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnRepositoryCloneFailed {
        pub cause: RepositoryCloneFailureCause,
        pub detail: ::std::string::String,
        #[serde(rename = "failedAt")]
        pub failed_at: ::chrono::DateTime<::chrono::FixedOffset>,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnRepositoryCloneFailedType,
    }
    ///`ChannelTurnRepositoryCloneFailedType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnRepositoryCloneFailedType {
        TurnRepositoryCloneFailed,
    }
    impl ::std::fmt::Display for ChannelTurnRepositoryCloneFailedType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnRepositoryCloneFailed => f.write_str("TurnRepositoryCloneFailed"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnRepositoryCloneFailedType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnRepositoryCloneFailed" => Ok(Self::TurnRepositoryCloneFailed),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnRepositoryCloneFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnRepositoryCloneFailedType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The box holds the session's repository and the harness is about to get the prompt; the first-line budget starts here.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnRepositoryReady {
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnRepositoryReadyType,
    }
    ///`ChannelTurnRepositoryReadyType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnRepositoryReadyType {
        TurnRepositoryReady,
    }
    impl ::std::fmt::Display for ChannelTurnRepositoryReadyType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnRepositoryReady => f.write_str("TurnRepositoryReady"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnRepositoryReadyType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnRepositoryReady" => Ok(Self::TurnRepositoryReady),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnRepositoryReadyType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnRepositoryReadyType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Takes the place of an unacked TurnOffer when the control plane resends it after its turn left
    ///Offered, so the resend keeps every `seq` and no key reaches a turn that already ended. It is also
    ///the answer to a TurnClaim for a turn that left Offered before the claim arrived: the host then
    ///hands the turn no prompt, keeps the box warm and reports nothing for the turn.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelTurnWithdrawn {
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        #[serde(rename = "type")]
        pub type_: ChannelTurnWithdrawnType,
    }
    ///`ChannelTurnWithdrawnType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelTurnWithdrawnType {
        TurnWithdrawn,
    }
    impl ::std::fmt::Display for ChannelTurnWithdrawnType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::TurnWithdrawn => f.write_str("TurnWithdrawn"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelTurnWithdrawnType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "TurnWithdrawn" => Ok(Self::TurnWithdrawn),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelTurnWithdrawnType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelTurnWithdrawnType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The control plane accepts the host. Both sides then resend their unacked frames.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ChannelWelcome {
        #[serde(rename = "hostId")]
        pub host_id: EntityId,
        #[serde(rename = "protocolVersion")]
        pub protocol_version: ::std::num::NonZeroU32,
        #[serde(rename = "type")]
        pub type_: ChannelWelcomeType,
    }
    ///`ChannelWelcomeType`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ChannelWelcomeType {
        Welcome,
    }
    impl ::std::fmt::Display for ChannelWelcomeType {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Welcome => f.write_str("Welcome"),
            }
        }
    }
    impl ::std::str::FromStr for ChannelWelcomeType {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Welcome" => Ok(Self::Welcome),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ChannelWelcomeType {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ChannelWelcomeType {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The sign-in code a person pastes after signing in at a Claude setup's signInUrl.
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ClaudeSetupCodeText(::std::string::String);
    impl ClaudeSetupCodeText {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ClaudeSetupCodeText {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ClaudeSetupCodeText {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ClaudeSetupCodeText {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ClaudeSetupCodeText {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ClaudeSetupCodeText> for ::std::string::String {
        fn from(value: ClaudeSetupCodeText) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ClaudeSetupCodeText {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 2000usize {
                return Err("ClaudeSetupCodeText: longer than 2000 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("ClaudeSetupCodeText: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ClaudeSetupCodeText {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ClaudeSetupCodeText {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ClaudeSetupCodeText {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///Why a Claude setup ended Failed. Each reason names the phase it stopped in.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ClaudeSetupFailureReason {
        SetupUrlMissing,
        CodeRejected,
        ClaudeCodeExited,
        SetupTimedOut,
        TokenNotStored,
        NoHostOnline,
        Superseded,
    }
    impl ::std::fmt::Display for ClaudeSetupFailureReason {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SetupUrlMissing => f.write_str("SetupUrlMissing"),
                Self::CodeRejected => f.write_str("CodeRejected"),
                Self::ClaudeCodeExited => f.write_str("ClaudeCodeExited"),
                Self::SetupTimedOut => f.write_str("SetupTimedOut"),
                Self::TokenNotStored => f.write_str("TokenNotStored"),
                Self::NoHostOnline => f.write_str("NoHostOnline"),
                Self::Superseded => f.write_str("Superseded"),
            }
        }
    }
    impl ::std::str::FromStr for ClaudeSetupFailureReason {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SetupUrlMissing" => Ok(Self::SetupUrlMissing),
                "CodeRejected" => Ok(Self::CodeRejected),
                "ClaudeCodeExited" => Ok(Self::ClaudeCodeExited),
                "SetupTimedOut" => Ok(Self::SetupTimedOut),
                "TokenNotStored" => Ok(Self::TokenNotStored),
                "NoHostOnline" => Ok(Self::NoHostOnline),
                "Superseded" => Ok(Self::Superseded),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ClaudeSetupFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ClaudeSetupFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`DisplayName`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct DisplayName(::std::string::String);
    impl DisplayName {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for DisplayName {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for DisplayName {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for DisplayName {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for DisplayName {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<DisplayName> for ::std::string::String {
        fn from(value: DisplayName) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for DisplayName {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 100usize {
                return Err("DisplayName: longer than 100 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("DisplayName: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for DisplayName {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for DisplayName {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for DisplayName {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`EmailAddress`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct EmailAddress(::std::string::String);
    impl EmailAddress {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for EmailAddress {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for EmailAddress {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for EmailAddress {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for EmailAddress {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<EmailAddress> for ::std::string::String {
        fn from(value: EmailAddress) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for EmailAddress {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 320usize {
                return Err("EmailAddress: longer than 320 characters".into());
            }
            if value.chars().count() < 3usize {
                return Err("EmailAddress: shorter than 3 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for EmailAddress {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for EmailAddress {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for EmailAddress {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`EntityId`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct EntityId(::std::string::String);
    impl EntityId {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for EntityId {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for EntityId {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for EntityId {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for EntityId {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<EntityId> for ::std::string::String {
        fn from(value: EntityId) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for EntityId {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 64usize {
                return Err("EntityId: longer than 64 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("EntityId: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for EntityId {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for EntityId {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for EntityId {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`Harness`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum Harness {
        ClaudeCode,
        Codex,
        OpenCode,
        PiDev,
        MistralAgent,
    }
    impl ::std::fmt::Display for Harness {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ClaudeCode => f.write_str("ClaudeCode"),
                Self::Codex => f.write_str("Codex"),
                Self::OpenCode => f.write_str("OpenCode"),
                Self::PiDev => f.write_str("PiDev"),
                Self::MistralAgent => f.write_str("MistralAgent"),
            }
        }
    }
    impl ::std::str::FromStr for Harness {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ClaudeCode" => Ok(Self::ClaudeCode),
                "Codex" => Ok(Self::Codex),
                "OpenCode" => Ok(Self::OpenCode),
                "PiDev" => Ok(Self::PiDev),
                "MistralAgent" => Ok(Self::MistralAgent),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for Harness {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for Harness {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`HarnessVersion`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct HarnessVersion(::std::string::String);
    impl HarnessVersion {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for HarnessVersion {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for HarnessVersion {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for HarnessVersion {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for HarnessVersion {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<HarnessVersion> for ::std::string::String {
        fn from(value: HarnessVersion) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for HarnessVersion {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("HarnessVersion: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for HarnessVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for HarnessVersion {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for HarnessVersion {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`HostArchitecture`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum HostArchitecture {
        Amd64,
        Arm64,
    }
    impl ::std::fmt::Display for HostArchitecture {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Amd64 => f.write_str("Amd64"),
                Self::Arm64 => f.write_str("Arm64"),
            }
        }
    }
    impl ::std::str::FromStr for HostArchitecture {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Amd64" => Ok(Self::Amd64),
                "Arm64" => Ok(Self::Arm64),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for HostArchitecture {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for HostArchitecture {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///What a host holds at one moment, sent on Hello and on every host Heartbeat. `boxesWarm` counts
    ///the paused boxes in their warm window, `loadAverage` is the one-minute load average of the host,
    ///and `memoryAvailableMib` is MemAvailable of /proc/meminfo in MiB.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct HostUsage {
        #[serde(rename = "boxesWarm")]
        pub boxes_warm: i32,
        #[serde(rename = "loadAverage")]
        pub load_average: f64,
        #[serde(rename = "memoryAvailableMib")]
        pub memory_available_mib: i64,
    }
    ///The harness of a guest image's GuestHarness: a catalog harness, or Shell for the test image the proof's Shell harness steps boot.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum ImageHarness {
        ClaudeCode,
        Codex,
        OpenCode,
        PiDev,
        MistralAgent,
        Shell,
    }
    impl ::std::fmt::Display for ImageHarness {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::ClaudeCode => f.write_str("ClaudeCode"),
                Self::Codex => f.write_str("Codex"),
                Self::OpenCode => f.write_str("OpenCode"),
                Self::PiDev => f.write_str("PiDev"),
                Self::MistralAgent => f.write_str("MistralAgent"),
                Self::Shell => f.write_str("Shell"),
            }
        }
    }
    impl ::std::str::FromStr for ImageHarness {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "ClaudeCode" => Ok(Self::ClaudeCode),
                "Codex" => Ok(Self::Codex),
                "OpenCode" => Ok(Self::OpenCode),
                "PiDev" => Ok(Self::PiDev),
                "MistralAgent" => Ok(Self::MistralAgent),
                "Shell" => Ok(Self::Shell),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for ImageHarness {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ImageHarness {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///A metric's declaration: its unit as OpenTelemetry writes it (s, MiB, {token}), its kind and what it measures.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct MetricInstrument {
        pub description: MetricInstrumentDescription,
        pub kind: MetricKind,
        pub metric: MetricName,
        pub unit: MetricInstrumentUnit,
    }
    ///`MetricInstrumentDescription`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct MetricInstrumentDescription(::std::string::String);
    impl MetricInstrumentDescription {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for MetricInstrumentDescription {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for MetricInstrumentDescription {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for MetricInstrumentDescription {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for MetricInstrumentDescription {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<MetricInstrumentDescription> for ::std::string::String {
        fn from(value: MetricInstrumentDescription) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for MetricInstrumentDescription {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("MetricInstrumentDescription: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for MetricInstrumentDescription {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for MetricInstrumentDescription {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for MetricInstrumentDescription {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`MetricInstrumentUnit`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct MetricInstrumentUnit(::std::string::String);
    impl MetricInstrumentUnit {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for MetricInstrumentUnit {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for MetricInstrumentUnit {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for MetricInstrumentUnit {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for MetricInstrumentUnit {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<MetricInstrumentUnit> for ::std::string::String {
        fn from(value: MetricInstrumentUnit) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for MetricInstrumentUnit {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() < 1usize {
                return Err("MetricInstrumentUnit: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for MetricInstrumentUnit {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for MetricInstrumentUnit {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for MetricInstrumentUnit {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`MetricKind`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum MetricKind {
        Turn,
        Sample,
    }
    impl ::std::fmt::Display for MetricKind {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Turn => f.write_str("Turn"),
                Self::Sample => f.write_str("Sample"),
            }
        }
    }
    impl ::std::str::FromStr for MetricKind {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Turn" => Ok(Self::Turn),
                "Sample" => Ok(Self::Sample),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for MetricKind {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for MetricKind {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///A metric name in the OpenTelemetry style: dotted lower-case segments, at most 64 characters.
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct MetricName(::std::string::String);
    impl MetricName {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for MetricName {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for MetricName {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for MetricName {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for MetricName {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<MetricName> for ::std::string::String {
        fn from(value: MetricName) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for MetricName {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 64usize {
                return Err("MetricName: longer than 64 characters".into());
            }
            static PATTERN: ::std::sync::LazyLock<::regress::Regex> =
                ::std::sync::LazyLock::new(|| ::regress::Regex::new("^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)*$").unwrap());
            if PATTERN.find(value).is_none() {
                return Err("MetricName: doesn't match pattern \"^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)*$\"".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for MetricName {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for MetricName {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for MetricName {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`ModelName`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct ModelName(::std::string::String);
    impl ModelName {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for ModelName {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for ModelName {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for ModelName {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for ModelName {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<ModelName> for ::std::string::String {
        fn from(value: ModelName) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for ModelName {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 200usize {
                return Err("ModelName: longer than 200 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("ModelName: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for ModelName {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for ModelName {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for ModelName {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///A path relative to the harness home in the box, such as .claude/settings.json. The harness catalog lists the paths each harness accepts.
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct PersonaFilePath(::std::string::String);
    impl PersonaFilePath {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for PersonaFilePath {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for PersonaFilePath {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for PersonaFilePath {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for PersonaFilePath {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<PersonaFilePath> for ::std::string::String {
        fn from(value: PersonaFilePath) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for PersonaFilePath {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 200usize {
                return Err("PersonaFilePath: longer than 200 characters".into());
            }
            static PATTERN: ::std::sync::LazyLock<::regress::Regex> =
                ::std::sync::LazyLock::new(|| ::regress::Regex::new("^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$").unwrap());
            if PATTERN.find(value).is_none() {
                return Err("PersonaFilePath: doesn't match pattern \"^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$\"".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for PersonaFilePath {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for PersonaFilePath {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for PersonaFilePath {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///The size of a persona file in bytes, at most PersonaFileLimit.PersonaBytes.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(transparent)]
    pub struct PersonaFileSize(pub i64);
    impl ::std::ops::Deref for PersonaFileSize {
        type Target = i64;
        fn deref(&self) -> &i64 {
            &self.0
        }
    }
    impl ::std::convert::From<PersonaFileSize> for i64 {
        fn from(value: PersonaFileSize) -> Self {
            value.0
        }
    }
    impl ::std::convert::From<i64> for PersonaFileSize {
        fn from(value: i64) -> Self {
            Self(value)
        }
    }
    impl ::std::fmt::Display for PersonaFileSize {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            self.0.fmt(f)
        }
    }
    impl ::std::str::FromStr for PersonaFileSize {
        type Err = <i64 as ::std::str::FromStr>::Err;
        fn from_str(value: &str) -> ::std::result::Result<Self, Self::Err> {
            Ok(Self(value.parse()?))
        }
    }
    impl ::std::convert::TryFrom<&str> for PersonaFileSize {
        type Error = <i64 as ::std::str::FromStr>::Err;
        fn try_from(value: &str) -> ::std::result::Result<Self, Self::Error> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<String> for PersonaFileSize {
        type Error = <i64 as ::std::str::FromStr>::Err;
        fn try_from(value: String) -> ::std::result::Result<Self, Self::Error> {
            value.parse()
        }
    }
    ///`Prompt`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct Prompt(::std::string::String);
    impl Prompt {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for Prompt {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for Prompt {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for Prompt {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for Prompt {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<Prompt> for ::std::string::String {
        fn from(value: Prompt) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for Prompt {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 100000usize {
                return Err("Prompt: longer than 100000 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("Prompt: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for Prompt {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for Prompt {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for Prompt {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///One harness layer of a release, for one harness version and architecture: a read-only squashfs
    ///image compressed with zstd whose root is `/opt/harness/<harness>/<harnessVersion>` in the box.
    ///The squashfs file and its HarnessLayerManifest document are stored under
    ///`layers/<harness>/<harnessVersion>/<arch>/<digest>` by `layerDigest` and `manifestDigest`.
    ///`sizeBytes` is the size of the squashfs file. A host attaches a layer only once its sha256
    ///matches `layerDigest`.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct ReleaseHarnessLayer {
        pub architecture: HostArchitecture,
        pub harness: ImageHarness,
        #[serde(rename = "harnessVersion")]
        pub harness_version: HarnessVersion,
        #[serde(rename = "layerDigest")]
        pub layer_digest: Sha256Digest,
        #[serde(rename = "manifestDigest")]
        pub manifest_digest: Sha256Digest,
        #[serde(rename = "sizeBytes")]
        pub size_bytes: ::std::num::NonZeroU64,
    }
    ///Why the box could not clone the session's repository.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum RepositoryCloneFailureCause {
        Refused,
        TimedOut,
        DirectoryNotEmpty,
        Other,
    }
    impl ::std::fmt::Display for RepositoryCloneFailureCause {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Refused => f.write_str("Refused"),
                Self::TimedOut => f.write_str("TimedOut"),
                Self::DirectoryNotEmpty => f.write_str("DirectoryNotEmpty"),
                Self::Other => f.write_str("Other"),
            }
        }
    }
    impl ::std::str::FromStr for RepositoryCloneFailureCause {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Refused" => Ok(Self::Refused),
                "TimedOut" => Ok(Self::TimedOut),
                "DirectoryNotEmpty" => Ok(Self::DirectoryNotEmpty),
                "Other" => Ok(Self::Other),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for RepositoryCloneFailureCause {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for RepositoryCloneFailureCause {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///`RepositoryUrl`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct RepositoryUrl(::std::string::String);
    impl RepositoryUrl {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for RepositoryUrl {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for RepositoryUrl {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for RepositoryUrl {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for RepositoryUrl {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<RepositoryUrl> for ::std::string::String {
        fn from(value: RepositoryUrl) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for RepositoryUrl {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 500usize {
                return Err("RepositoryUrl: longer than 500 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("RepositoryUrl: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for RepositoryUrl {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for RepositoryUrl {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for RepositoryUrl {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///One value of a Sample metric at a moment, with its dimensions.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct SamplePoint {
        pub at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub dimensions: ::std::collections::HashMap<::std::string::String, ::std::string::String>,
        pub metric: MetricName,
        pub value: f64,
    }
    ///`Sequence`
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    #[serde(transparent)]
    pub struct Sequence(pub i64);
    impl ::std::ops::Deref for Sequence {
        type Target = i64;
        fn deref(&self) -> &i64 {
            &self.0
        }
    }
    impl ::std::convert::From<Sequence> for i64 {
        fn from(value: Sequence) -> Self {
            value.0
        }
    }
    impl ::std::convert::From<i64> for Sequence {
        fn from(value: i64) -> Self {
            Self(value)
        }
    }
    impl ::std::fmt::Display for Sequence {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            self.0.fmt(f)
        }
    }
    impl ::std::str::FromStr for Sequence {
        type Err = <i64 as ::std::str::FromStr>::Err;
        fn from_str(value: &str) -> ::std::result::Result<Self, Self::Err> {
            Ok(Self(value.parse()?))
        }
    }
    impl ::std::convert::TryFrom<&str> for Sequence {
        type Error = <i64 as ::std::str::FromStr>::Err;
        fn try_from(value: &str) -> ::std::result::Result<Self, Self::Error> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<String> for Sequence {
        type Error = <i64 as ::std::str::FromStr>::Err;
        fn try_from(value: String) -> ::std::result::Result<Self, Self::Error> {
            value.parse()
        }
    }
    ///A lower-case hex SHA-256 digest: the name of a file in the image cache, or of a persona file blob.
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct Sha256Digest(::std::string::String);
    impl Sha256Digest {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for Sha256Digest {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for Sha256Digest {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for Sha256Digest {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for Sha256Digest {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<Sha256Digest> for ::std::string::String {
        fn from(value: Sha256Digest) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for Sha256Digest {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            static PATTERN: ::std::sync::LazyLock<::regress::Regex> =
                ::std::sync::LazyLock::new(|| ::regress::Regex::new("^[0-9a-f]{64}$").unwrap());
            if PATTERN.find(value).is_none() {
                return Err("Sha256Digest: doesn't match pattern \"^[0-9a-f]{64}$\"".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for Sha256Digest {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for Sha256Digest {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for Sha256Digest {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///`StorageKey`
    #[derive(::serde::Serialize, Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    #[serde(transparent)]
    pub struct StorageKey(::std::string::String);
    impl StorageKey {
        pub fn as_str(&self) -> &str {
            &self.0
        }
    }
    impl ::std::convert::AsRef<str> for StorageKey {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }
    impl ::std::fmt::Display for StorageKey {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            f.write_str(&self.0)
        }
    }
    impl ::std::convert::AsRef<::std::ffi::OsStr> for StorageKey {
        fn as_ref(&self) -> &::std::ffi::OsStr {
            self.0.as_ref()
        }
    }
    impl ::std::ops::Deref for StorageKey {
        type Target = ::std::string::String;
        fn deref(&self) -> &::std::string::String {
            &self.0
        }
    }
    impl ::std::convert::From<StorageKey> for ::std::string::String {
        fn from(value: StorageKey) -> Self {
            value.0
        }
    }
    impl ::std::str::FromStr for StorageKey {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            if value.chars().count() > 1000usize {
                return Err("StorageKey: longer than 1000 characters".into());
            }
            if value.chars().count() < 1usize {
                return Err("StorageKey: shorter than 1 characters".into());
            }
            Ok(Self(value.to_string()))
        }
    }
    impl ::std::convert::TryFrom<&str> for StorageKey {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for StorageKey {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl<'de> ::serde::Deserialize<'de> for StorageKey {
        fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
        where
            D: ::serde::Deserializer<'de>,
        {
            ::std::string::String::deserialize(deserializer)?
                .parse()
                .map_err(|e: self::error::ConversionError| <D::Error as ::serde::de::Error>::custom(e.to_string()))
        }
    }
    ///Why a supervisor update stopped. Every one but SupervisorUpdateRolledBack leaves the running binary in place.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum SupervisorUpdateFailureReason {
        SupervisorUpdateFetchFailed,
        SupervisorUpdateChecksumMismatch,
        SupervisorUpdateDryRunFailed,
        SupervisorUpdateStateUnreadable,
        SupervisorUpdateIdleTimedOut,
        SupervisorUpdateSwapFailed,
        SupervisorUpdateRolledBack,
    }
    impl ::std::fmt::Display for SupervisorUpdateFailureReason {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::SupervisorUpdateFetchFailed => f.write_str("SupervisorUpdateFetchFailed"),
                Self::SupervisorUpdateChecksumMismatch => f.write_str("SupervisorUpdateChecksumMismatch"),
                Self::SupervisorUpdateDryRunFailed => f.write_str("SupervisorUpdateDryRunFailed"),
                Self::SupervisorUpdateStateUnreadable => f.write_str("SupervisorUpdateStateUnreadable"),
                Self::SupervisorUpdateIdleTimedOut => f.write_str("SupervisorUpdateIdleTimedOut"),
                Self::SupervisorUpdateSwapFailed => f.write_str("SupervisorUpdateSwapFailed"),
                Self::SupervisorUpdateRolledBack => f.write_str("SupervisorUpdateRolledBack"),
            }
        }
    }
    impl ::std::str::FromStr for SupervisorUpdateFailureReason {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "SupervisorUpdateFetchFailed" => Ok(Self::SupervisorUpdateFetchFailed),
                "SupervisorUpdateChecksumMismatch" => Ok(Self::SupervisorUpdateChecksumMismatch),
                "SupervisorUpdateDryRunFailed" => Ok(Self::SupervisorUpdateDryRunFailed),
                "SupervisorUpdateStateUnreadable" => Ok(Self::SupervisorUpdateStateUnreadable),
                "SupervisorUpdateIdleTimedOut" => Ok(Self::SupervisorUpdateIdleTimedOut),
                "SupervisorUpdateSwapFailed" => Ok(Self::SupervisorUpdateSwapFailed),
                "SupervisorUpdateRolledBack" => Ok(Self::SupervisorUpdateRolledBack),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for SupervisorUpdateFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for SupervisorUpdateFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///The phase a supervisor update entered. Fetching downloads and verifies the candidate binary,
    ///DryRunning runs it with `check` beside the running binary and keeps it once it passes, Staged
    ///is what supervisors before the box handover send while a candidate waits for the host to run no
    ///box, Restarting swaps the binaries, parks every running turn and execs the new one, which takes
    ///over the running boxes, and Online is the new binary reaching Welcome. WaitingForIdle is what supervisors before the idle claim send between DryRunning and
    ///Restarting; the control plane accepts it and records nothing.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum SupervisorUpdatePhase {
        Fetching,
        DryRunning,
        Staged,
        WaitingForIdle,
        Restarting,
        Online,
    }
    impl ::std::fmt::Display for SupervisorUpdatePhase {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::Fetching => f.write_str("Fetching"),
                Self::DryRunning => f.write_str("DryRunning"),
                Self::Staged => f.write_str("Staged"),
                Self::WaitingForIdle => f.write_str("WaitingForIdle"),
                Self::Restarting => f.write_str("Restarting"),
                Self::Online => f.write_str("Online"),
            }
        }
    }
    impl ::std::str::FromStr for SupervisorUpdatePhase {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "Fetching" => Ok(Self::Fetching),
                "DryRunning" => Ok(Self::DryRunning),
                "Staged" => Ok(Self::Staged),
                "WaitingForIdle" => Ok(Self::WaitingForIdle),
                "Restarting" => Ok(Self::Restarting),
                "Online" => Ok(Self::Online),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for SupervisorUpdatePhase {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for SupervisorUpdatePhase {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///Why a turn ended Failed. Each reason names the phase the turn stopped in.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
    pub enum TurnFailureReason {
        NotClaimed,
        Undelivered,
        NoFirstOutput,
        HostOffline,
        CredentialRefused,
        DispatchCredentialExpired,
        CredentialExpired,
        BoxBootFailed,
        PoolExhausted,
        SnapshotUnreadable,
        HarnessExited,
        HarnessOutOfMemory,
        HarnessExitedWithoutResult,
        TurnTimedOut,
        TranscriptGap,
        PersonaFileUnreadable,
        RepositoryCloneFailed,
        HarnessReportedError,
        RepositoryTokenRefused,
        ImageNotReleased,
        ImageFetchFailed,
        ImageFetchTimedOut,
        HostUpdating,
        BoxLost,
    }
    impl ::std::fmt::Display for TurnFailureReason {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match *self {
                Self::NotClaimed => f.write_str("NotClaimed"),
                Self::Undelivered => f.write_str("Undelivered"),
                Self::NoFirstOutput => f.write_str("NoFirstOutput"),
                Self::HostOffline => f.write_str("HostOffline"),
                Self::CredentialRefused => f.write_str("CredentialRefused"),
                Self::DispatchCredentialExpired => f.write_str("DispatchCredentialExpired"),
                Self::CredentialExpired => f.write_str("CredentialExpired"),
                Self::BoxBootFailed => f.write_str("BoxBootFailed"),
                Self::PoolExhausted => f.write_str("PoolExhausted"),
                Self::SnapshotUnreadable => f.write_str("SnapshotUnreadable"),
                Self::HarnessExited => f.write_str("HarnessExited"),
                Self::HarnessOutOfMemory => f.write_str("HarnessOutOfMemory"),
                Self::HarnessExitedWithoutResult => f.write_str("HarnessExitedWithoutResult"),
                Self::TurnTimedOut => f.write_str("TurnTimedOut"),
                Self::TranscriptGap => f.write_str("TranscriptGap"),
                Self::PersonaFileUnreadable => f.write_str("PersonaFileUnreadable"),
                Self::RepositoryCloneFailed => f.write_str("RepositoryCloneFailed"),
                Self::HarnessReportedError => f.write_str("HarnessReportedError"),
                Self::RepositoryTokenRefused => f.write_str("RepositoryTokenRefused"),
                Self::ImageNotReleased => f.write_str("ImageNotReleased"),
                Self::ImageFetchFailed => f.write_str("ImageFetchFailed"),
                Self::ImageFetchTimedOut => f.write_str("ImageFetchTimedOut"),
                Self::HostUpdating => f.write_str("HostUpdating"),
                Self::BoxLost => f.write_str("BoxLost"),
            }
        }
    }
    impl ::std::str::FromStr for TurnFailureReason {
        type Err = self::error::ConversionError;
        fn from_str(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            match value {
                "NotClaimed" => Ok(Self::NotClaimed),
                "Undelivered" => Ok(Self::Undelivered),
                "NoFirstOutput" => Ok(Self::NoFirstOutput),
                "HostOffline" => Ok(Self::HostOffline),
                "CredentialRefused" => Ok(Self::CredentialRefused),
                "DispatchCredentialExpired" => Ok(Self::DispatchCredentialExpired),
                "CredentialExpired" => Ok(Self::CredentialExpired),
                "BoxBootFailed" => Ok(Self::BoxBootFailed),
                "PoolExhausted" => Ok(Self::PoolExhausted),
                "SnapshotUnreadable" => Ok(Self::SnapshotUnreadable),
                "HarnessExited" => Ok(Self::HarnessExited),
                "HarnessOutOfMemory" => Ok(Self::HarnessOutOfMemory),
                "HarnessExitedWithoutResult" => Ok(Self::HarnessExitedWithoutResult),
                "TurnTimedOut" => Ok(Self::TurnTimedOut),
                "TranscriptGap" => Ok(Self::TranscriptGap),
                "PersonaFileUnreadable" => Ok(Self::PersonaFileUnreadable),
                "RepositoryCloneFailed" => Ok(Self::RepositoryCloneFailed),
                "HarnessReportedError" => Ok(Self::HarnessReportedError),
                "RepositoryTokenRefused" => Ok(Self::RepositoryTokenRefused),
                "ImageNotReleased" => Ok(Self::ImageNotReleased),
                "ImageFetchFailed" => Ok(Self::ImageFetchFailed),
                "ImageFetchTimedOut" => Ok(Self::ImageFetchTimedOut),
                "HostUpdating" => Ok(Self::HostUpdating),
                "BoxLost" => Ok(Self::BoxLost),
                _ => Err("invalid value".into()),
            }
        }
    }
    impl ::std::convert::TryFrom<&str> for TurnFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: &str) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    impl ::std::convert::TryFrom<::std::string::String> for TurnFailureReason {
        type Error = self::error::ConversionError;
        fn try_from(value: ::std::string::String) -> ::std::result::Result<Self, self::error::ConversionError> {
            value.parse()
        }
    }
    ///One value of a Turn metric, with the turn and session it belongs to.
    #[derive(::serde::Deserialize, ::serde::Serialize, Clone, Debug, PartialEq)]
    pub struct TurnPoint {
        pub at: ::chrono::DateTime<::chrono::FixedOffset>,
        pub dimensions: ::std::collections::HashMap<::std::string::String, ::std::string::String>,
        pub metric: MetricName,
        #[serde(rename = "sessionId")]
        pub session_id: EntityId,
        #[serde(rename = "turnId")]
        pub turn_id: EntityId,
        pub value: f64,
    }
    /// Error types.
    pub mod error {
        /// Error from a `TryFrom` or `FromStr` implementation.
        pub struct ConversionError(::std::borrow::Cow<'static, str>);
        impl ::std::error::Error for ConversionError {}
        impl ::std::fmt::Display for ConversionError {
            fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> Result<(), ::std::fmt::Error> {
                ::std::fmt::Display::fmt(&self.0, f)
            }
        }
        impl ::std::fmt::Debug for ConversionError {
            fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> Result<(), ::std::fmt::Error> {
                ::std::fmt::Debug::fmt(&self.0, f)
            }
        }
        impl From<&'static str> for ConversionError {
            fn from(value: &'static str) -> Self {
                Self(value.into())
            }
        }
        impl From<String> for ConversionError {
            fn from(value: String) -> Self {
                Self(value.into())
            }
        }
    }
}
impl types::ChannelCloseCode {
    pub const PROTOCOL_ERROR: u16 = 4400;
    pub const BAD_SIGNATURE: u16 = 4401;
    pub const REVOKED: u16 = 4403;
    pub const HEARTBEAT_DEADLINE: u16 = 4408;
    pub const REPLACED: u16 = 4409;
    pub const UNSUPPORTED_VERSION: u16 = 4426;
}
