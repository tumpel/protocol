use std::collections::HashMap;
use std::num::{NonZeroU32, NonZeroU64};

use progenitor_client::{ByteStream, ResponseValue};

pub trait ContainsUnrecognised {
    fn contains_unrecognised(&self) -> bool;
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for ResponseValue<T> {
    fn contains_unrecognised(&self) -> bool {
        self.as_ref().contains_unrecognised()
    }
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for Option<T> {
    fn contains_unrecognised(&self) -> bool {
        self.as_ref().is_some_and(ContainsUnrecognised::contains_unrecognised)
    }
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for Vec<T> {
    fn contains_unrecognised(&self) -> bool {
        self.iter().any(ContainsUnrecognised::contains_unrecognised)
    }
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for Box<T> {
    fn contains_unrecognised(&self) -> bool {
        self.as_ref().contains_unrecognised()
    }
}

impl<T: ContainsUnrecognised, S> ContainsUnrecognised for HashMap<String, T, S> {
    fn contains_unrecognised(&self) -> bool {
        self.values().any(ContainsUnrecognised::contains_unrecognised)
    }
}

macro_rules! always_recognised {
    ($($ty:ty),+ $(,)?) => {
        $(impl ContainsUnrecognised for $ty {
            fn contains_unrecognised(&self) -> bool {
                false
            }
        })+
    };
}

always_recognised!(
    (),
    bool,
    f64,
    i32,
    i64,
    u16,
    String,
    NonZeroU32,
    NonZeroU64,
    chrono::DateTime<chrono::FixedOffset>,
    serde_json::Value,
    serde_json::Map<String, serde_json::Value>,
    ByteStream,
);

macro_rules! unrecognised {
    ($ty:ident, $($field:tt),*) => {
        impl $crate::ContainsUnrecognised for $ty {
            fn contains_unrecognised(&self) -> bool {
                false $(|| $crate::ContainsUnrecognised::contains_unrecognised(&self.$field))*
            }
        }
    };
    ($ty:ident) => {
        impl $crate::ContainsUnrecognised for $ty {
            fn contains_unrecognised(&self) -> bool {
                matches!(self, Self::Unrecognised(..))
            }
        }
    };
}
macro_rules! unrecognised_union {
    ($ty:ident, $($variant:ident),+) => {
        impl $crate::ContainsUnrecognised for $ty {
            fn contains_unrecognised(&self) -> bool {
                match self {
                    $(Self::$variant(value) => $crate::ContainsUnrecognised::contains_unrecognised(value),)+
                    Self::Unrecognised(..) => true,
                }
            }
        }
    };
}

pub(crate) use {unrecognised, unrecognised_union};
