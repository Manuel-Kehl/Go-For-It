public interface TodoListInfo : Object{

    public abstract string id {
        get;
    }

    public abstract string plugin_name {
        get;
    }

    public abstract string name {
        get;
        set;
    }
}
