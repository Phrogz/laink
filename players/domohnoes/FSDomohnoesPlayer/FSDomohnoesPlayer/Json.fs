module Json

open Newtonsoft.Json
open System
open System.IO
open System.Text
open System.Collections

// Helper
let pukeJson (s:string) =
  use f = new System.IO.StreamWriter( "puke.json" )
  f.Write( sprintf "%O\n" s )
  let j = new JsonTextReader( new StringReader(s) )
  while j.Read() do
    f.Write( sprintf "  %O\n" j.TokenType )
    f.Write( sprintf "    %O: %O\n" j.ValueType j.Value )

let toJson (o:obj) =
  let rec emitObj (o:obj) writer =
    match o with
      | :? ArrayList as a -> emitArrayList a writer
      | :? Hashtable as h -> emitHashTable h writer
      | _ -> writer.WriteValue(o) // This is ballsy, and might be bad. Add more cases as necessary.

  and emitArrayList a (writer:JsonTextWriter) =
    writer.WriteStartArray()
    for o in a do emitObj o writer
    writer.WriteEnd()

  and emitHashTable h (writer:JsonTextWriter) =
    writer.WriteStartObject()
    for k in h.Keys do
      writer.WritePropertyName(k.ToString())
      emitObj h.[k] writer
    writer.WriteEnd()

  let sb = StringBuilder()
  use j = new JsonTextWriter(new StringWriter(sb))
  emitObj o j
  sb.ToString()

let fromJson (s:string) =
  let rec getObj (reader:JsonTextReader) =
    match reader.TokenType with
      | JsonToken.StartObject -> getHashtable reader :> obj
      | JsonToken.StartArray  -> getArrayList reader :> obj
      | JsonToken.Integer     -> Int32.Parse(reader.Value.ToString()) :> obj
      | _                     -> reader.Value // This is ballsy, and might be bad. Add more cases as necessary.

  and getArrayList (reader:JsonTextReader) =
    let a = new ArrayList()
    reader.Read() |> ignore
    while reader.TokenType <> JsonToken.EndArray do
      a.Add(getObj reader) |> ignore
      reader.Read() |> ignore
    a

  and getHashtable (reader:JsonTextReader) =
    let h = new Hashtable()
    reader.Read() |> ignore
    while reader.TokenType <> JsonToken.EndObject do
      let k = reader.Value
      reader.Read() |> ignore
      let v = getObj reader
      h.Add(k,v)
      reader.Read() |> ignore
    h

  let j = new JsonTextReader(new StringReader(s))
  j.Read() |> ignore
  getObj j
