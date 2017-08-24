public interface Iterator<G> : Object {
    public abstract bool valid {
        get;
    }

    public abstract bool next ();
    public abstract bool has_next ();
    
    /**
     * Returns the current element in the iteration. 
     */
    public abstract G get ();
}
