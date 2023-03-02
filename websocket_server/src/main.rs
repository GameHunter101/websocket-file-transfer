use std::{
    collections::HashMap,
    fs::File,
    io::{prelude::*, Error as IoError},
    net::SocketAddr,
    path::Path,
    sync::{Arc, Mutex},
};

use serde::{Deserialize, Serialize};
use serde_json;

use futures_channel::mpsc::{unbounded, UnboundedSender};
use futures_util::{future, pin_mut, stream::TryStreamExt, StreamExt};

use local_ip_address::local_ip;
use tokio::net::{TcpListener, TcpStream};
use tungstenite::protocol::Message;

type Tx = UnboundedSender<Message>;
type PeerMap = Arc<Mutex<HashMap<SocketAddr, Tx>>>;

#[derive(Serialize, Deserialize, Debug)]
struct FileMetaData {
    name: String,
    extension: String,
    size: String,
}

fn decode_binary_data(binary_data: Vec<u8>, path: &str) -> serde_json::Result<()> {
    let length_bytes = &binary_data[0..4];
    let meta_data_length = (i32::from_le_bytes([
        length_bytes[0],
        length_bytes[1],
        length_bytes[2],
        length_bytes[3],
    ]) + 4) as usize;
    let meta_data_bytes = &binary_data[4..meta_data_length];
    let meta_data_string = std::str::from_utf8(meta_data_bytes).unwrap_or_default();
    let meta_data: FileMetaData = serde_json::from_str(meta_data_string)?;
	let file_data = &binary_data[meta_data_length..binary_data.len()];
    let full_path = Path::new(&path)
        .join(format!("{}.{}", meta_data.name, meta_data.extension))
        .display()
        .to_string();
	let _file = create_file(full_path, file_data);
    // println!("{:?}", meta_data);
    Ok(())
}

fn create_file(path: String, data: &[u8]) -> std::io::Result<()> {
    let mut file = File::create(path)?;
    file.write_all(data)?;
    Ok(())
}

async fn handle_connection(
    peer_map: PeerMap,
    raw_stream: TcpStream,
    addr: SocketAddr,
) -> serde_json::Result<()> {
    println!("Incoming TCP connection from: {}", addr);

    let ws_stream = tokio_tungstenite::accept_async(raw_stream)
        .await
        .expect("Error during the websocket handshake occurred");
    println!("WebSocket connection established: {}", addr);

    // Insert the write part of this peer to the peer map.
    let (tx, rx) = unbounded();
    peer_map.lock().unwrap().insert(addr, tx);

    let (outgoing, incoming) = ws_stream.split();

    let broadcast_incoming = incoming.try_for_each(|msg| {
        if msg.is_binary() {
            // println!("BINARY DATA, {:?}", msg.into_data());
            let _data = decode_binary_data(msg.into_data(), "C:\\Users\\liors\\Documents\\Coding projects\\websocket file transfer\\websocket_server\\destination");
        } else {
            println!(
                "Received a message from {}: {}",
                addr,
                msg.to_text().unwrap()
            );
        }
        future::ok(())
    });

    let receive_from_others = rx.map(Ok).forward(outgoing);

    pin_mut!(broadcast_incoming, receive_from_others);
    future::select(broadcast_incoming, receive_from_others).await;

    println!("{} disconnected", &addr);
    peer_map.lock().unwrap().remove(&addr);
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), IoError> {
    let mut addr = local_ip().unwrap().to_string();
    if let Some(test) = TcpListener::bind("127.0.0.1:0")
        .await
        .unwrap()
        .local_addr()
        .ok()
    {
        println!("Free port at: {:?}", test.port());
        addr = addr+":60116"/* +&test.port().to_string() */;
    }

    let state = PeerMap::new(Mutex::new(HashMap::new()));

    // Create the event loop and TCP listener we'll accept connections on.
    let try_socket = TcpListener::bind(&addr).await;
    let listener = try_socket.expect("Failed to bind");
    println!("Listening on: {}", addr);

    // Let's spawn the handling of each connection in a separate task.
    while let Ok((stream, addr)) = listener.accept().await {
        tokio::spawn(handle_connection(state.clone(), stream, addr));
    }

    Ok(())
}
