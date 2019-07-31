extern crate chrono;

use std::net::UdpSocket;
use std::fs::OpenOptions;
use std::io::prelude::*;
use std::fs::File;
use std::io::Result;
use chrono::prelude::*;

//const LOG_SIZE: usize = 524288000;
const LOG_SIZE: usize = 200;

#[derive(Debug)]
struct RecvData {
    host: Vec<u8>,
    content: Vec<u8>,
}

impl RecvData {
    pub fn new(host: Vec<u8>, content: Vec<u8>) -> Self {
        Self {
            host,
            content,
        }
    }
}

fn init_host(host: &str) -> UdpSocket {
    let socket = UdpSocket::bind(host).expect("failed to bind host socket");
    socket
}

fn recv_msg(socket: &UdpSocket) -> RecvData {
    let mut buf: [u8; 2000] = [0; 2000];
    let mut result: Vec<u8> = Vec::new();
    let mut host: Vec<u8> = Vec::new();
    match socket.recv_from(&mut buf) {
        Ok((number_of_bytes, src_addr)) => {
            result = Vec::from(&buf[0..number_of_bytes]);
            host = Vec::from(src_addr.ip().to_string());
        }
        Err(fail) => println!("failed listening {:?}", fail)
    }
    RecvData::new(host, result)
}

fn get_file_handle() -> Result<File> {
    let path = "/Users/hg/Sites/youyou_log/";
    let name = Local::now().format("%Y%m%d-%H%M%S").to_string() + ".log";
    let filename = format!("{}{}", path, name);
    OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .append(true)
        .open(filename)
}

fn write_log(fs: &mut Result<File>, content: Vec<u8>) -> Result<usize> {
    let mut len = 0;
    match fs {
        Ok(stream) => {
            stream.write_all(&content)?;
            len = content.len();
        }
        Err(err) => {
            println!("{:?}", err);
        }
    }
    Ok(len)
}

fn formart_log(recv: &mut RecvData, cur_time: DateTime<Local>) -> Vec<u8> {
    let host = &recv.host;
    let time: Vec<u8> = Vec::from(cur_time.format("%Y-%m-%d %H:%M:%S ").to_string());
    let content = &recv.content;
    //换行
    let newline: Vec<u8> = vec![10];
    [&time[..], &host[..], &content[..], &newline[..]].concat()
}

fn main() {
    let socket = init_host("127.0.0.1:34254");
    let mut file_handle = get_file_handle();
    let mut log_size = 0;
    let mut day: u32 = Local::now().day();
    loop {
        let mut recv_data = recv_msg(&socket);
        let cur_time = Local::now();
        let cur_day = cur_time.day();
        //如果不是同一天 或 文件大小超出，使用新的文件
        if cur_day != day || log_size >= LOG_SIZE {
            log_size = 0;
            day = cur_day;
            file_handle = get_file_handle();
        }
        let data: Vec<u8> = formart_log(&mut recv_data, cur_time);
        let len = write_log(&mut file_handle, data).unwrap();
        log_size = log_size + len;
        println!("{:?}", log_size);
    }
}
