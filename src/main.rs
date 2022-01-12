use actix_web::{web, App, HttpServer, HttpRequest};

async fn index(req: HttpRequest) -> &'static str {
    println!("REQ: {:?}", req);
    "Hello world!"
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    std::env::set_var("RUST_LOG", "actix_web=info");

    println!("Starting server...");
    HttpServer::new(|| {
        App::new()
            .service(web::resource("/").to(index))
    })
    .bind("0.0.0.0:8000")?
    .run()
    .await
}
