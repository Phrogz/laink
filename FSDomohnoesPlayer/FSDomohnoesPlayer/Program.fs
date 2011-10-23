//TODO: Factor the general Player-ness out of this into a resuable thing.

open Newtonsoft.Json
open System.Net.Sockets
open System.Text
open System.IO

let utf8 = Encoding.UTF8

let command (c:string) (a:string[]) =
  let sb = StringBuilder()
  use sw = new StringWriter(sb)
  use j = new JsonTextWriter(sw)
  j.WriteStartObject()
  j.WritePropertyName("command")
  j.WriteValue(c)
  j.WritePropertyName("args")
  j.WriteStartArray()
  Array.iter (fun (s:string) -> j.WriteValue(s)) a
  j.WriteEnd()
  j.WriteEndObject()
  sb.ToString()

let pukeJSON (s:string) =
  printfn "%O" s
  let j = new JsonTextReader( new StringReader(s) )
  let mutable weDone = false
  while j.Read() do
    printfn "  %O" j.TokenType
    printfn "    %O: %O" j.ValueType j.Value

let gameType = "com.danceliquid.domohnoes"

let streamWrite (stream:NetworkStream) (s:string) =
  let b = utf8.GetBytes(s)
  let l = b.Length
  stream.Write(b, 0, l)

let streamRead (stream:NetworkStream) =
  let size = 2<<<16-1
  let response = Array.create size ((byte)0)
  let l = stream.Read( response, 0, size )
  System.String(utf8.GetChars( response, 0, l ))

let stream = (new TcpClient("localhost", 54147)).GetStream()

let interact cmd =
  streamWrite stream cmd
  pukeJSON (streamRead stream)

interact (command "gametype_supported" [| gameType |])
interact (command "start_game" [| gameType |])
interact (command "goodbye" [| |])
