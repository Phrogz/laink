//TODO: Factor the general Player-ness out of this into a resuable thing.

open System.Net.Sockets
open System.Text

let utf8 = Encoding.UTF8

let command c (a:string[]) =
  let sb = StringBuilder()
  sb.Append "[" |> ignore
  Array.iter (fun s -> sb.Append (sprintf "\"%s\"" s) |> ignore ) a
  sb.Append "]" |> ignore
  sprintf "{\"command\":\"%s\", \"args\":%s}" c (sb.ToString())

let gameType = "com.danceliquid.domohnoes"

let streamWrite (stream:NetworkStream) (s:string) =
  let b = utf8.GetBytes(s)
  let l = b.Length
  stream.Write(b, 0, l)

let s = new System.Net.Sockets.TcpClient("localhost", 54147)
let stream = s.GetStream()

let size = 2<<<16-1
let response = Array.create size ((byte)0)
let mutable l = 0

streamWrite stream (command "gametype_supported" [| gameType |])
l <- stream.Read( response, 0, size )
printfn "%O" (System.String(utf8.GetChars( response, 0, l )))

streamWrite stream (command "start_game" [| gameType |])
l <- stream.Read( response, 0, size )
printfn "%O" (System.String(utf8.GetChars( response, 0, l )))

streamWrite stream (command "goodbye" [| |])
l <- stream.Read( response, 0, size )
printfn "%O" (System.String(utf8.GetChars( response, 0, l )))
