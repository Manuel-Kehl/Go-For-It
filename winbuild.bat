windres data\app-icon.rs -o data\app-icon.o
valac --pkg gtk+-3.0 -X data\app-icon.o -X -mwindows src\*.vala src\view\*.vala
move "Main.exe" "dist\Go For It!.exe"