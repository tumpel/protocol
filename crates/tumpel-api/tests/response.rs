use std::time::Duration;

use reqwest::StatusCode;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpListener;
use tumpel_api::types::{ConfigPlan, Problem};
use tumpel_api::{ByteStream, Client, ContainsUnrecognised, Error, ResponseValue};

#[tokio::test]
async fn responses_flag_only_a_nested_unrecognised_value() {
    for (action, unrecognised) in [("FutureAction", true), ("Create", false)] {
        let body = format!(
            r#"{{"changes":[{{"action":"Create","resource":"Persona","name":"first","description":"first change"}},{{"action":"{action}","resource":"Persona","name":"second","description":"second change"}}]}}"#
        );
        let response = reqwest::Response::from(http::Response::new(body));
        let decoded = ResponseValue::<ConfigPlan>::from_response::<Problem>(response)
            .await
            .unwrap();
        assert_eq!(decoded.is_unrecognised(), unrecognised);
    }
}

async fn installation(
    status: &str,
    content_type: &str,
    body: &str,
) -> Result<Result<ResponseValue<ByteStream>, Error<Problem>>, Box<dyn std::error::Error>> {
    let listener = TcpListener::bind("127.0.0.1:0").await?;
    let address = listener.local_addr()?;
    let client = Client::new_with_client(
        &format!("http://{address}"),
        reqwest::Client::builder().no_proxy().build()?,
    );
    let server = async {
        let (socket, _) = listener.accept().await?;
        let mut socket = BufReader::new(socket);
        let mut line = String::new();
        socket.read_line(&mut line).await?;
        assert_eq!(line, "GET /v1/releases/install.sh HTTP/1.1\r\n");
        loop {
            line.clear();
            assert_ne!(socket.read_line(&mut line).await?, 0);
            if line == "\r\n" {
                break;
            }
        }
        let response = format!(
            "HTTP/1.1 {status}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
            body.len()
        );
        socket.get_mut().write_all(response.as_bytes()).await
    };
    let (written, response) = tokio::time::timeout(Duration::from_secs(5), async {
        tokio::join!(server, client.releases_install())
    })
    .await?;
    written?;
    Ok(response)
}

#[tokio::test]
async fn a_generated_typed_error_matches_and_converts_with_the_same_response_type() {
    let outcome = installation(
        "400 Bad Request",
        "application/problem+json",
        r#"{"code":"FutureRefusal","title":"Future refusal","detail":"future detail","fix":"future fix"}"#,
    )
    .await
    .expect("the test server serves the request");
    let Err(Error::ErrorResponse(response)) = outcome else {
        panic!("the generated client returns a typed problem");
    };
    assert!(response.is_unrecognised());
    let status = response.status();
    assert_eq!(status, StatusCode::BAD_REQUEST);
    let headers = response.headers().clone();
    assert_eq!(headers[reqwest::header::CONTENT_TYPE], "application/problem+json");
    let problem: Problem = response.into_inner();
    assert_eq!(problem.title.as_str(), "Future refusal");
    let error: Error<Problem> = Error::ErrorResponse(ResponseValue::new(problem, status, headers.clone()));
    let Error::ErrorResponse(response) = error.into_untyped() else {
        panic!("the converted error keeps its response");
    };
    assert_eq!(response.status(), status);
    assert_eq!(response.headers(), &headers);
}

#[tokio::test]
async fn consuming_a_generated_stream_response_preserves_its_bytes() {
    let response = installation("200 OK", "text/plain", "download bytes")
        .await
        .expect("the test server serves the request")
        .expect("the generated client receives a download");
    assert_eq!(response.status(), StatusCode::OK);
    assert_eq!(response.content_length(), Some(14));
    assert!(!response.is_unrecognised());
    let mut stream = response.into_inner_stream();
    let mut body = Vec::new();
    while let Some(chunk) = std::future::poll_fn(|cx| stream.as_mut().poll_next(cx)).await {
        body.extend_from_slice(&chunk.unwrap());
    }
    assert_eq!(body, b"download bytes");
}
