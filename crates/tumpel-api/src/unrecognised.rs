use std::collections::HashMap;
use std::num::{NonZeroU32, NonZeroU64};

pub trait ContainsUnrecognised {
    fn contains_unrecognised(&self) -> bool;
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
    String,
    NonZeroU32,
    NonZeroU64,
    chrono::DateTime<chrono::FixedOffset>,
    serde_json::Value,
    serde_json::Map<String, serde_json::Value>,
);

macro_rules! fields_contain_unrecognised {
    ($ty:ident, $($field:tt),*) => {
        impl $crate::ContainsUnrecognised for $ty {
            fn contains_unrecognised(&self) -> bool {
                false $(|| $crate::ContainsUnrecognised::contains_unrecognised(&self.$field))*
            }
        }
    };
}

macro_rules! unrecognised_union {
    ($ty:ident, [$($payload:ident),*], [$($unit:ident),*]) => {
        impl $crate::ContainsUnrecognised for $ty {
            fn contains_unrecognised(&self) -> bool {
                match self {
                    $(Self::$payload(value) => $crate::ContainsUnrecognised::contains_unrecognised(value),)*
                    $(Self::$unit => false,)*
                    Self::Unrecognised(..) => true,
                }
            }
        }
    };
}

pub(crate) use {fields_contain_unrecognised, unrecognised_union};
