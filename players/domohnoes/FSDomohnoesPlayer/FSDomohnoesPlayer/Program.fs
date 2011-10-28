//TODO: Factor the general Player-ness out of this into a resuable thing.

open Newtonsoft.Json
open System
open System.Net.Sockets
open System.Text
open System.IO

let utf8 = Encoding.UTF8

type CommandDetail =
  | S of string
  | L of Collections.Generic.List<int>
type CommandDetails = Collections.Generic.Dictionary<String,CommandDetail>

let getJson (d:CommandDetails) =
  let sb = StringBuilder()
  use j = new JsonTextWriter(new StringWriter(sb))
  j.WriteStartObject()
  for k in d.Keys do
    j.WritePropertyName(k)
    match d.[k] with
      | S s -> j.WriteValue(s)
      | L l -> j.WriteStartArray()
               Seq.iter (fun (i:int) -> j.WriteValue(i)) l
               j.WriteEnd()
  j.WriteEndObject()
  sb.ToString()

type JSONSocket(c:TcpClient) =
  member self.Command( t, (details:CommandDetails) ) =
    details.Add("command",t)
    self.SendData( details )

  member self.Error( t, (details:CommandDetails) ) =
    details.Add("error",t)
    self.SendData( details )

  member self.OnRecieve( f ) =
    f (self.ReadData())

  member self.SendData( data ) =
    let b = utf8.GetBytes(getJson data)
    let l = b.Length
    let stream = c.GetStream()
    let hb = BitConverter.GetBytes( int16 l )
    let temp = hb.[0]
    hb.[0] <- hb.[1]; hb.[1] <- temp
    stream.Write( hb, 0, 2 )
    stream.Write( b, 0, l)

  member self.ReadData() =
    let stream = c.GetStream()
    let header = Array.create 2 ((byte)0)
    stream.Read( header, 0, 2 ) |> ignore
    let l = BitConverter.ToInt16( header, 0 )
    let size = ((int)l)
    let response = Array.create size ((byte)0)
    let l = stream.Read( response, 0, size )
    String(utf8.GetChars( response, 0, size )).Trim(Array.create 1 ((char)0))

let pukeJSON (s:string) =
  printfn "%O" s
  let j = new JsonTextReader( new StringReader(s) )
  let mutable weDone = false
  while j.Read() do
    printfn "  %O" j.TokenType
    printfn "    %O: %O" j.ValueType j.Value

let gameType = "com.danceliquid.domohnoes"

let socket = new JSONSocket( new TcpClient("localhost", 54147) )

let startGameData = new CommandDetails()
startGameData.Add("gametype", S(gameType))
startGameData.Add("nick", S("F# Doms Player"))
socket.Command(S("start_game"), startGameData)

// TODO: loop ;)
socket.OnRecieve pukeJSON
