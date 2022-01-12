use actix_web::{get, App, HttpServer, HttpResponse, Responder};

const GREETINGS: &str = "Hello world!";

#[get("/")]
async fn index() -> impl Responder {
    HttpResponse::Ok().body(GREETINGS)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    std::env::set_var("RUST_LOG", "actix_web=info");

    println!("Starting server...");
    HttpServer::new(|| {
        App::new()
            .service(index)
    })
    .bind("0.0.0.0:8000")?
    .run()
    .await
}
