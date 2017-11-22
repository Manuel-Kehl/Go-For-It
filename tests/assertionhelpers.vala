private bool compare_uint (uint a, uint b) {
    bool same = a == b;
    if (!same) {
        stdout.printf ("%u != %u\n", a, b);
    }
    return same;
}

private bool compare_string (string a, string b) {
    bool same = a == b;
    if (!same) {
        stdout.printf ("%s != %s\n", a, b);
    }
    return same;
}

private bool compare_bool (bool a, bool b) {
    bool same = a == b;
    if (!same) {
        stdout.printf ("%s != %s\n", a.to_string (), b.to_string ());
    }
    return same;
}
