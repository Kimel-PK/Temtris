while (true) do
	
	-- kolizje
	
	local x = memory.readbyte(0x0018) - 1;
	local y = memory.readbyte(0x0019) + 1;
	
	-- kolizja z prawej
	if AND(memory.readbyte(0x0013), BIT(0)) == BIT(0) then
		gui.box(x + 33, y, x + 35, y + 31, "red");
	end;
	-- kolizja z dołu
	if AND(memory.readbyte(0x0013), BIT(1)) == BIT(1) then
		gui.box(x, y + 32, x + 32, y + 34, "red");
	end;
	-- kolizja z lewej
	if AND(memory.readbyte(0x0013), BIT(2)) == BIT(2) then
		gui.box(x - 2, y, x, y + 31, "red");
	end;
	-- kolizja po obrocie w prawo
	if AND(memory.readbyte(0x0013), BIT(3)) == BIT(3) then
		gui.text(x + 28, y - 16, ">", "red");
	end;
	-- kolizja po obrocie w lewo
	if AND(memory.readbyte(0x0013), BIT(4)) == BIT(4) then
		gui.text(x + 3, y - 16, "<", "red");
	end;
	-- kolizja po obrocie w prawo z przesunięciem
	if AND(memory.readbyte(0x0013), BIT(5)) == BIT(5) then
		gui.text(x + 18, y - 16, "=>", "red");
	end;
	-- kolizja po obrocie w lewo z przesunięciem
	if AND(memory.readbyte(0x0013), BIT(6)) == BIT(6) then
		gui.text(x + 8, y - 16, "<=", "red");
	end;
	
	-- mapa kolizji
	
	local xk = 201;
	local yk = 11;
	
	gui.box(xk - 1, yk - 1, xk + 24, yk + 20, "black", "blue");
	for i = 0, 4 do
		for j = 0, 5 do
			if memory.readbyte(0x0021 + (i * 6) + j) > 0 then
				gui.box(xk + j * 4, yk + i * 4, xk + 3 + j * 4, yk + 3 + i * 4, "green");
			end
		end
	end
	
	gui.box(xk + 4 + ((memory.readbyte(0x0203) - x) / 2), yk + 1 + ((memory.readbyte(0x0200) - y) / 2), xk + 7 + ((memory.readbyte(0x0203) - x) / 2), yk + 4 + ((memory.readbyte(0x0200) - y) / 2), "yellow");
	gui.box(xk + 4 + ((memory.readbyte(0x0207) - x) / 2), yk + 1 + ((memory.readbyte(0x0204) - y) / 2), xk + 7 + ((memory.readbyte(0x0207) - x) / 2), yk + 4 + ((memory.readbyte(0x0204) - y) / 2), "yellow");
	gui.box(xk + 4 + ((memory.readbyte(0x020B) - x) / 2), yk + 1 + ((memory.readbyte(0x0208) - y) / 2), xk + 7 + ((memory.readbyte(0x020B) - x) / 2), yk + 4 + ((memory.readbyte(0x0208) - y) / 2), "yellow");
	gui.box(xk + 4 + ((memory.readbyte(0x020F) - x) / 2), yk + 1 + ((memory.readbyte(0x020C) - y) / 2), xk + 7 + ((memory.readbyte(0x020F) - x) / 2), yk + 4 + ((memory.readbyte(0x020C) - y) / 2), "yellow");
	
	-- ogólne
	gui.text(2, 10, "Czas gry: "..memory.readbyte(0x00A4)..memory.readbyte(0x00A5)..memory.readbyte(0x00A6)..":"..memory.readbyte(0x00A7)..memory.readbyte(0x00A8));
	gui.text(2, 18, "Numer poziomu: "..memory.readbyte(0x0012));
	
	-- linie
	for i = 0, 19 do
		gui.text(171, 49 + i * 8, memory.readbyte(0x003F + i));
	end
	
	FCEU.frameadvance();
end;