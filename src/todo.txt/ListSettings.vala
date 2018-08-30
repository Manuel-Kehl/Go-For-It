class ListSettings {

    public string id {
        get {
            return _id;
        }
    }
    string _id;

    public string name {
        get;
        set;
    }

    public string todo_txt_location {
        get;
        set;
    }

    public int task_duration {
        get;
        set;
    }
    public int break_duration {
        get;
        set;
    }
    public int reminder_time {
        get;
        set;
    }

    public ListSettings (string id, string name, string location) {
        this._id = id;
        this.name = name;
        this.todo_txt_location = location;

        this.task_duration = -1;
        this.break_duration = -1
        this.reminder_time = -1;
    }
}
