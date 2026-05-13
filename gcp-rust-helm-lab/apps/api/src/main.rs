use axum::{routing::get, Json, Router};
use serde::Serialize;
use std::net::SocketAddr;

#[derive(Serialize)]
struct ApiResponse {
    service: &'static str,
    status: &'static str,
    message: &'static str,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter("rust_api=info,tower_http=info")
        .init();

    let app = Router::new()
        .route("/healthz", get(healthz))
        .route("/dummy", get(dummy));

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("bind API listener");

    axum::serve(listener, app).await.expect("run API server");
}

async fn healthz() -> Json<ApiResponse> {
    Json(ApiResponse {
        service: "rust-api",
        status: "ok",
        message: "healthy",
    })
}

async fn dummy() -> Json<ApiResponse> {
    Json(ApiResponse {
        service: "rust-api",
        status: "ok",
        message: "dummy thing",
    })
}
