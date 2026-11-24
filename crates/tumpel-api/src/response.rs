use std::collections::HashMap;
use std::num::{NonZeroU32, NonZeroU64};

use progenitor_client::{ByteStream, ResponseValue};

pub trait ContainsUnrecognised {
    fn is_unrecognised(&self) -> bool;
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for ResponseValue<T> {
    fn is_unrecognised(&self) -> bool {
        self.as_ref().is_unrecognised()
    }
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for Option<T> {
    fn is_unrecognised(&self) -> bool {
        self.as_ref().is_some_and(ContainsUnrecognised::is_unrecognised)
    }
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for Vec<T> {
    fn is_unrecognised(&self) -> bool {
        self.iter().any(ContainsUnrecognised::is_unrecognised)
    }
}

impl<T: ContainsUnrecognised> ContainsUnrecognised for Box<T> {
    fn is_unrecognised(&self) -> bool {
        self.as_ref().is_unrecognised()
    }
}

impl<T: ContainsUnrecognised, S> ContainsUnrecognised for HashMap<String, T, S> {
    fn is_unrecognised(&self) -> bool {
        self.values().any(ContainsUnrecognised::is_unrecognised)
    }
}

macro_rules! always_recognised {
    ($($ty:ty),+ $(,)?) => {
        $(impl ContainsUnrecognised for $ty {
            fn is_unrecognised(&self) -> bool {
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
            fn is_unrecognised(&self) -> bool {
                false $(|| $crate::ContainsUnrecognised::is_unrecognised(&self.$field))*
            }
        }
    };
    ($ty:ident) => {
        impl $crate::ContainsUnrecognised for $ty {
            fn is_unrecognised(&self) -> bool {
                matches!(self, Self::Unrecognised(..))
            }
        }
    };
}
pub(crate) use unrecognised;
