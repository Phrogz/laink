namespace Buffoon

// Plays highest pips
type Buffoon() =
  let r = new System.Random()
  interface Doms.IPlayer with
    member this.GetName() = "F# Buffoon"
    member this.GetMove( inTurnOptions ) = r.Next(inTurnOptions.Count)
