main:
	zig build-exe src\main.zig
	./main.exe

clean:
	-del build\*.exe build\*.pdb
	-del *.exe *.pdb *.obj
