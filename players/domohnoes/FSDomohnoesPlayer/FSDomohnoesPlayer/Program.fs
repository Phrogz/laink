open System.Net.Sockets
open System.Collections

open Json
open JsonSocket

type turnoption  = Doms.TurnOption
type turnoptions = Generic.List<turnoption>
type board       = Generic.List<int>
type dom         = Doms.Dom
type doms        = Generic.List<dom>
type side        = Doms.Side

let getTurnOptions (inHand:doms) (inBoard:board) =
  let proposeHand d (h:doms) =
    let newHand = new doms( h )
    newHand.Remove(d) |> ignore
    newHand
  let proposeBoard (s:side) (d:dom) (b:board) =
    let newBoard = match s with
                   | side.Front -> if d.r = b.[0]         then [| d.GetList(); b |] else [| d.GetReverseList(); b |]
                   | side.Back  -> if d.l = b.[b.Count-1] then [| b; d.GetList() |] else [| b; d.GetReverseList() |]
                   | _ -> [| new board() |]
    new board( Seq.concat newBoard )
  let proposeOpeningBoard (d:dom) =
    new board( d.GetList() )

  if inBoard.Count=0 then
    new turnoptions(Seq.map (fun d -> new turnoption(d, side.Front, proposeHand d inHand, proposeOpeningBoard d)) inHand)
  else
    let first = inBoard.[0]
    let last  = inBoard.[inBoard.Count-1]
    let choices = List.ofSeq (Seq.concat ([| Seq.map (fun d -> (side.Front, d)) (Seq.filter (fun (d:dom) -> d.l = first ) inHand);
                                             Seq.map (fun d -> (side.Back,  d)) (Seq.filter (fun (d:dom) -> d.l = last  ) inHand);
                                             Seq.map (fun d -> (side.Front, d)) (Seq.filter (fun (d:dom) -> d.r = first ) inHand);
                                             Seq.map (fun d -> (side.Back,  d)) (Seq.filter (fun (d:dom) -> d.r = last  ) inHand) |]))
    new turnoptions(Seq.map (fun (s, d) -> new turnoption(d, s, proposeHand d inHand, proposeBoard s d inBoard)) choices)

let makeHand (a:ArrayList) =
  let h = new doms()
  for d in a do
    let l = (d:?>ArrayList).[0] :?> int
    let r = (d:?>ArrayList).[1] :?> int
    h.Add( new dom(l,r) )
  h

let makeBoard (a:ArrayList) =
  let b = new board()
  for d in a do
    b.Add( (d:?>ArrayList).[0] :?> int )
    b.Add( (d:?>ArrayList).[1] :?> int )
  b

let command (s:JsonSocket) (c:string) (h:Hashtable) =
  h.Add("command", c)
  s.SendData(toJson h)

let socket = new JsonSocket( new TcpClient("localhost", 54147) )
let r = new System.Random()

let startGameData = new Hashtable()
startGameData.Add("gametype", "com.danceliquid.domohnoes")
startGameData.Add("nick", "F# Doms Player")
command socket "start_game" startGameData

let mutable weDone = false
while weDone=false do
  let s = socket.ReadData()
  let h = fromJson s :?> Hashtable
  if h.["command"] :?> string = "move" then
    let state = (h.["state"] :?> Hashtable)
    let h = makeHand  (state.["hand"]  :?> ArrayList)
    let b = makeBoard (state.["board"] :?> ArrayList)

    let moveData = new Hashtable()

    let options = getTurnOptions h b
    if options.Count=0 then
      moveData.Add("action", "chapped")
    else
      let move = options.[ r.Next(options.Count) ] // TODO: Call into .dll
      moveData.Add("action", "play")
      let a = new ArrayList()
      a.Add( move.played.l ) |> ignore
      a.Add( move.played.r ) |> ignore
      moveData.Add("domino", a)
      moveData.Add("edge", if move.side = side.Front then "front" else "back")
    command socket "move" moveData
  elif h.["command"] :?> string = "gameover" then
    printfn "Game Over: %O" s
    weDone <- true
  else
    printfn "Weird message: %O" s

printfn "DONE"