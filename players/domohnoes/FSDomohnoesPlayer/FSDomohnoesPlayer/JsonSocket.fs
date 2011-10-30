module JsonSocket

open System
open System.Collections
open System.Text
open System.Net.Sockets

open Json

let utf8 = Encoding.UTF8

let endianSwap (b:byte[]) =
  Array.Reverse b

type JsonSocket(c:TcpClient) =
  member self.SendData(data:string) =
    let b = utf8.GetBytes(data)
    let l = b.Length
    let stream = c.GetStream()
    let hb = BitConverter.GetBytes( int16 l )
    if BitConverter.IsLittleEndian then Array.Reverse hb
    stream.Write( hb, 0, 2 )
    stream.Write( b, 0, l)

  member self.ReadData() =
    let stream = c.GetStream()
    let header = Array.create 2 ((byte)0)
    stream.Read( header, 0, 2 ) |> ignore
    if BitConverter.IsLittleEndian then Array.Reverse header
    let l = BitConverter.ToInt16( header, 0 )
    let size = ((int)l)
    let response = Array.create size ((byte)0)
    let l = stream.Read( response, 0, size )
    String(utf8.GetChars( response, 0, size )).Trim(Array.create 1 ((char)0))
