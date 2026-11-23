use std::cell::Cell;
use std::ops::{Deref, DerefMut};

use progenitor_client::{ByteStream, Error};
use serde::{de::DeserializeOwned, Deserialize, Deserializer};

thread_local! {
    static UNRECOGNISED: Cell<bool> = const { Cell::new(false) };
}

pub(crate) fn mark_unrecognised<T>(value: T) -> T {
    UNRECOGNISED.set(true);
    value
}

pub(crate) fn unrecognised<'de, T: Deserialize<'de>, D: Deserializer<'de>>(deserializer: D) -> Result<T, D::Error> {
    T::deserialize(deserializer).map(mark_unrecognised)
}

pub(crate) fn attempt<'de, T: Deserialize<'de>, D: Deserializer<'de>>(deserializer: D) -> Result<T, D::Error> {
    let previous = UNRECOGNISED.get();
    let value = T::deserialize(deserializer);
    if value.is_err() {
        UNRECOGNISED.set(previous);
    }
    value
}

#[derive(Debug)]
struct Decoded<T> {
    value: T,
    unrecognised: bool,
}

impl<'de, T: Deserialize<'de>> Deserialize<'de> for Decoded<T> {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        let previous = UNRECOGNISED.replace(false);
        let value = T::deserialize(deserializer);
        let unrecognised = UNRECOGNISED.replace(previous);
        Ok(Self {
            value: value?,
            unrecognised,
        })
    }
}

#[derive(Debug)]
pub struct ResponseValue<T> {
    inner: progenitor_client::ResponseValue<T>,
    unrecognised: bool,
}

impl<T: DeserializeOwned> ResponseValue<T> {
    #[expect(
        clippy::result_large_err,
        reason = "the generated client returns progenitor_client::Error"
    )]
    pub async fn from_response<E>(response: reqwest::Response) -> Result<Self, Error<E>> {
        let decoded = progenitor_client::ResponseValue::<Decoded<T>>::from_response(response).await?;
        let status = decoded.status();
        let headers = decoded.headers().clone();
        let Decoded { value, unrecognised } = decoded.into_inner();
        Ok(Self {
            inner: progenitor_client::ResponseValue::new(value, status, headers),
            unrecognised,
        })
    }
}

impl<T> ResponseValue<T> {
    pub fn new(inner: T, status: reqwest::StatusCode, headers: reqwest::header::HeaderMap) -> Self {
        Self {
            inner: progenitor_client::ResponseValue::new(inner, status, headers),
            unrecognised: false,
        }
    }

    pub fn is_unrecognised(&self) -> bool {
        self.unrecognised
    }

    pub fn into_inner(self) -> T {
        self.inner.into_inner()
    }

    pub fn status(&self) -> reqwest::StatusCode {
        self.inner.status()
    }

    pub fn headers(&self) -> &reqwest::header::HeaderMap {
        self.inner.headers()
    }

    pub fn content_length(&self) -> Option<u64> {
        self.inner.content_length()
    }

    pub fn map<U: std::fmt::Debug, F: FnOnce(T) -> U, E>(self, f: F) -> Result<ResponseValue<U>, E> {
        Ok(ResponseValue {
            inner: self.inner.map(f)?,
            unrecognised: self.unrecognised,
        })
    }
}

impl ResponseValue<()> {
    #[must_use]
    pub fn empty(response: reqwest::Response) -> Self {
        Self {
            inner: progenitor_client::ResponseValue::empty(response),
            unrecognised: false,
        }
    }
}

impl ResponseValue<ByteStream> {
    #[must_use]
    pub fn stream(response: reqwest::Response) -> Self {
        Self {
            inner: progenitor_client::ResponseValue::stream(response),
            unrecognised: false,
        }
    }
}

impl<T> Deref for ResponseValue<T> {
    type Target = T;

    fn deref(&self) -> &T {
        &self.inner
    }
}

impl<T> DerefMut for ResponseValue<T> {
    fn deref_mut(&mut self) -> &mut T {
        &mut self.inner
    }
}

impl<T> AsRef<T> for ResponseValue<T> {
    fn as_ref(&self) -> &T {
        &self.inner
    }
}
