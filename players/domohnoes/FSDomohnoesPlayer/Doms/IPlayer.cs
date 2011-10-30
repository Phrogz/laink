using System.Collections.Generic;

namespace Doms
{
    public enum Side{ Front, Back }

    public class Dom
    {
        public int l;
        public int r;
        public Dom(int inL, int inR)
        {
            l = inL;
            r = inR;
        }
        public List<int> GetList()        { return new List<int> { l, r }; }
        public List<int> GetReverseList() { return new List<int> { r, l }; }
        public override string ToString() { return "("+l+", "+r+")"; }
    }

    public class TurnOption
    {
        public Dom played;      // The dom from your hand which would be played
        public Side side;       // The side that it would be played on
        public List<Dom> hand;  // Your hand after you play that dom
        public List<int> board; // The new board after you play that dom
        public TurnOption(Dom inPlayed, Side inSide, List<Dom> inHand, List<int> inBoard)
        {
            played = inPlayed;
            side = inSide;
            hand = inHand;
            board = inBoard;
        }
    }

    public interface IPlayer
    {
        string GetName();
        int    GetMove(List<TurnOption> inTurnOptions);
    }
}
