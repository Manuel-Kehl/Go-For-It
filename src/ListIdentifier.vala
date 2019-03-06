/* Copyright 2019 Go For It! developers
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* Go For It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Go For It!. If not, see http://www.gnu.org/licenses/.
*/

[Compact]
private class GOFI.ListIdentifier {
    public string provider;
    public string id;

    public ListIdentifier (string provider, string id) {
        this.provider = provider;
        this.id = id;
    }

    public static ListIdentifier? from_string (string encoded) {
        var concat_identifier = split_strings (encoded);
        if (concat_identifier[1] != null) {
            return new ListIdentifier (
                concat_identifier[0],
                concat_identifier[1]
            );
        }
        return null;
    }

    public static ListIdentifier from_info (TodoListInfo info) {
        return new ListIdentifier (info.provider_name, info.id);
    }

    public string to_string () {
        return merge_strings (this.provider, this.id);
    }

    private static string merge_strings (string str1, string str2) {
        var _str1 = str1.replace (":\"", "\\:\"");
        var _str2 = str2.replace (":\"", "\\:\"");
        return "\"" + _str1 + "\":\"" + _str2 + "\"";
    }

    private static string[] split_strings (string str) {
        string[] temp = str.slice(1,-1).split ("\":\"");
        for (int i = 0; i < temp.length; i++) {
            temp[i] = temp[i].replace ("\\:\"", ":\"");
        }
        return temp;
    }
}
