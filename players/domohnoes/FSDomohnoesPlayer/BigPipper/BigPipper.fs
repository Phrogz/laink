namespace BigPipper

type dom = Doms.Dom
type turnoption = Doms.TurnOption

// Plays highest pips
type BigPipper() =
  interface Doms.IPlayer with
    member this.GetName() = "Big-Pipper"
    member this.GetMove( inTurnOptions ) =
      fst (Seq.maxBy (fun (d:(int*dom)) -> Seq.sum ((snd d).GetList()))
            (Seq.mapi (fun i (t:turnoption) -> (i, t.played)) inTurnOptions))