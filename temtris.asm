.segment "HEADER"

.byte "NES"
.byte $1A ; MS-DOS EOF
.byte $02 ; rozmiar PRG ROM
.byte $02 ; rozmiar CHR ROM
.byte %00111000 ; %MMMMvTsm - M - mapper bity niskie, v - 4 ekranowy VRAM, T - trainer, s - bateria, m - mirroring
.byte %00000000 ; %MMMM---- - M - mapper bity wysokie
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00

.segment "ZEROPAGE"

; lista rejestrów z nazwami

; kontrolery
JOYPAD1 = $4016
JOYPAD2 = $4017

; PPU
PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
OAMADDR = $2003
OAMDATA = $2004
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007
OAMDMA = $4014

; APU
APUSTATUS = $4015

; zmienne tymczasowe
temp: .res 2
int: .res 2
tempX: .res 1
tempY: .res 1

; zmienne zarządzania wejściem
kontroler: .res 1 ; ABsSUDLR
kontrolerpoprzedni: .res 1
zegarKontrolera: .res 1
zegarKontroleraszybkosc: .res 1
zegarKontroleraobrot: .res 1

; zmienne sterujące
losowa: .res 2
trybGry: .res 1
numerGracza: .res 1
pauza: .res 1
zegarSpadania: .res 1
szybkoscSpadania: .res 1
poziom: .res 1

; zmienne klocka
kolizja: .res 1 ; %XYZBALDP kolizja - X - koniec gry, Y - kolizja po obrocie w lewo z przesunieciem, Z - kolizja po obrocie w prawo z przesunieciem, B - przy obrocie w lewo, A - przy obrocie w prawo, L - z lewej, D - z dołu, P - z prawej)
numerKlocka: .res 1
numerNastepnegoKlocka1: .res 1
numerNastepnegoKlocka2: .res 1
obrotKlocka: .res 1
pozycjaKlockaX: .res 1 ; lewy górny róg siatki kostki 4x4
pozycjaKlockaY: .res 1
pozycjaPPUH: .res 1 ; lewy górny róg siatki kolizji 6x5 (-1 komórka PPU względem pozycji klocka 4x4)
pozycjaPPUL: .res 1
pozycjaLiniiKlocka: .res 1 ; potrzebne do liczenia wypełnienia linii
pozycjaDanychKlocka: .res 2 ; wskaźnik do obecnie używanych danych klocka
pozycjaDanychNastepnegoKlocka: .res 2 ; wskaźnik do danych następnego klocka
mapaKolizji: .res 30

; linie i punktacja
wypelnienieLinii: .res 20
liczbaLiniiNastepnyPoziom: .res 1
liczbaLinii1BCD: .res 4
liczbaLinii2BCD: .res 4
punkty1BCD: .res 4
punkty2BCD: .res 4
odczytLinii: .res 1
zapisLinii: .res 1
zrzutLinii: .res 10
ileNaRazLinii: .res 1

; muzyka
wlaczMuzyke: .res 1 ; -----PTN - aktywne kanały
grajMuzykeMenu: .res 1
odtwarzajMuzykeLosowo: .res 1
zegarMuzykiP: .res 1
zegarMuzykiT: .res 1
zegarMuzykiN: .res 1

odtwarzanaMuzykaP: .res 2
odtwarzanaMuzykaT: .res 2
odtwarzanaMuzykaN: .res 2

wskaznikDoMuzykiP: .res 2
wskaznikDoMuzykiT: .res 2
wskaznikDoMuzykiN: .res 2

; statystyki
linieCheems1BCD: .res 4
linieDoge1BCD: .res 4
linieBuffDoge1BCD: .res 4
linieTemtris1BCD: .res 4

linieCheems2BCD: .res 4
linieDoge2BCD: .res 4
linieBuffDoge2BCD: .res 4
linieTemtris2BCD: .res 4

zegarCzasGry: .res 1
czasGryBCD: .res 5

; animacja rozbijanej linii
klatkaAnimacji: .res 1
blokAnimacji: .res 1

; pozostała pamięć
pozostaloBajtow: .res 84

.segment "STARTUP"

Sponsor:
	.byte "Sponsor projektu: r/Rudzia      "

; =========================================================
; ===================== główny program ====================
; =========================================================

; ===================== inicjalizacja =====================

START:
	SEI ; wylaczyc przerwania
	CLD ; wylaczyc tryb dziesietny
	
	JSR ZerujAPU
	
	LDA #$40
	STA JOYPAD2
	
	; inicjalizacja stosu
	LDX #$FF
	TXS
	
	; rządanie przerwania IRQ
	LDA #$00
	STA $4010
	
	JSR CzekajNaVBLANK
	
	JSR WylaczPPU
	
	; czyść dane spriteów
	LDA #$FF
	LDX #$00
:
	STA $0200, X
	INX
	BNE :-
	
	JSR TransferOAMDMA
	
	; załaduj chr bank 1
	LDA #$01
	STA $8000
	
	; wyczyść palety
	LDA #$3F
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	LDX #$00
	
:
	LDA #$0F
	STA PPUDATA
	INX
	CPX #$20
	BNE :-
	
	; wybierz adres w PPU
	BIT PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	LDX #$00
	LDY #$00
	
	; wyczyść ekran
:
	LDA #$00
	STA PPUDATA
	INY
	CPX #$03
	BNE :+
	CPY #$CF
	BEQ :++
:
	CPY #$00
	BNE :--
	INX
	JMP :--
	
:
	
	; załaduj atrybuty ekranu
	LDA #<GrafikaTloMenu
	STA int
	LDA #>GrafikaTloMenu
	STA int+1
	
	CLC
	LDA int
	ADC #$CF
	STA int
	LDA int+1
	ADC #$03
	STA int+1
	
	LDY #$00
:
	LDA (int), Y
	STA PPUDATA
	INY
	CPY #$30
	BNE :-
	
	LDA #<GitHub
	STA int
	LDA #>GitHub
	STA int+1
	
	; wybierz adres w PPU
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$66
	STA PPUADDR
	
	LDY #$00
	
	; napisz link GitHuba
:
	LDA (int), Y
	STA PPUDATA
	INY
	CPY #$13
	BEQ :+
	JMP :-
:
	
	LDA #$40
	STA int
	
	; wybierz adres w PPU
	LDA #$21
	STA temp
	LDA #$CB
	STA temp+1
	
	LDX #$00
	LDY #$00
	
	; narysuj awatar
:
	BIT PPUSTATUS
	LDA temp
	STA PPUADDR
	LDA temp+1
	STA PPUADDR
:
	LDA int
	STA PPUDATA
	INC int
	INX
	INY
	CPY #$30
	BEQ :++
	
	CPX #$08
	BNE :+
	
	CLC
	LDA temp+1
	ADC #$20
	STA temp+1
	LDA temp
	ADC #$00
	STA temp
	
	LDX #$00
	
	JMP :--
	
:
	JMP :--
:
	
	JSR WyzerujScrollowanie
	
	LDA #%00010000 ; wybieramy bank 2 z pliku .chr do tła
	STA PPUCTRL
	
	; włacz sprite i tło
	LDA #%00011110
	STA PPUMASK
	
	LDA #$20
	STA temp
	LDA #$04
	STA temp+1
	LDX #$00
	LDY #$00
	
	LDA #$00
	STA numerGracza
	STA tempY
	
:
	JSR CzytajKontroler
	JSR WyzerujScrollowanie
	JSR CzekajNaVBLANK
	
	; naciśnij start żeby rozpocząć
	LDA kontroler
	AND #%00010000
	CMP #%00010000
	BNE :+
	
	LDA kontrolerpoprzedni
	AND #%00010000
	CMP #%00000000
	BNE :+
	
	JMP LadowanieMenu
:
	
	DEC temp
	LDA temp
	CMP #$00
	BNE :--
	
	LDA #%00101111
	STA $4004
	LDA #%10111010
	STA $4005
	LDA #%11111111
	STA $4006
	LDA #%11111111
	STA $4007
	
	JSR GitHubUstawPaleteRozjasnij
	LDA #$20
	STA temp
	
	DEC temp+1
	LDA temp+1
	CMP #$00
	BNE :--
	
	LDX #$B4
:
	JSR CzytajKontroler
	JSR WyzerujScrollowanie
	JSR CzekajNaVBLANK
	
	; naciśnij start żeby rozpocząć
	LDA kontroler
	AND #%00010000
	CMP #%00010000
	BNE :+
	
	LDA kontrolerpoprzedni
	AND #%00010000
	CMP #%00000000
	BNE :+
	
	JMP LadowanieMenu
:
	
	DEX
	CPX #$00
	BNE :--
	
LadowanieMenu:
	
	; czyść pamieć
	LDA #$00
	LDX #$00
:
	STA $0000, X
	STA $0100, X
	STA $0300, X
	STA $0400, X
	STA $0500, X
	STA $0600, X
	STA $0700, X
	INX
	BNE :-
	
	; inicjalizacja ziarna
	LDA #$21
	STA losowa
	LDA #$37
	STA losowa+1
	
	JSR CzekajNaVBLANK
	
	JSR WylaczPPU
	
	; załaduj chr bank 0
	LDA #$00
	STA $8000
	
	; załaduj palety ($3F00)
	LDA #$3F
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	LDX #$00
	
:
	LDA DanePalet, X
	STA PPUDATA
	INX
	CPX #$20
	BNE :-

	; narysuj tlo menu na ekranie
	
	; zapisz wskaznik do zmiennej int
	LDA #<GrafikaTloMenu
	STA int
	LDA #>GrafikaTloMenu
	STA int+1
	
	; wybierz adres w PPU
	BIT PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	; zeruj rejestry i zmienne
	LDX #$00
	LDY #$00
	
	; wczytaj GrafikaTloMenu
:
	LDA (int), Y
	STA PPUDATA
	INY
	CPX #$03
	BNE :+
	CPY #$FF
	BEQ :++
:
	CPY #$00
	BNE :--
	INX
	INC int+1
	JMP :--
	
:
	
	; wyzeruj scrollowanie
	LDA #$00
	STA PPUSCROLL
	STA PPUSCROLL
	
	; załaduj sprite strzałki wyboru graczy
	LDA #$A7
	STA $0200
	LDA #$00
	STA $0201
	LDA #$00
	STA $0202
	LDA #$26
	STA $0203
	
	LDA #%00010000 ; wybieramy bank 1 z pliku .chr do tła
	STA PPUCTRL
	
	; włacz sprite i tło
	LDA #%00011110
	STA PPUMASK
	
	LDA #$3C
	STA szybkoscSpadania
	
	LDA #$FF
	STA klatkaAnimacji
	
	STA kontroler
	STA kontrolerpoprzedni
	
	LDA #$01
	STA odtwarzajMuzykeLosowo
	STA grajMuzykeMenu
	
	JSR MuzykaGrajIntro
	
	LDA #%00000111
	STA wlaczMuzyke
	
; =========================================================
; ======================== stany gry ======================
; =========================================================

StanMenuGry:
	
	JSR Losuj
	JSR CzytajKontroler
	JSR OdtwarzajMuzyke
	
	JSR CzekajNaVBLANK
	
	; naciśnij start żeby rozpocząć
	LDA kontroler
	AND #%00010000
	CMP #%00010000
	BNE :+
	
	LDA kontrolerpoprzedni
	AND #%00010000
	CMP #%00000000
	BNE :+
	
	JMP StanLadowanieGry
	
:
	; naciśnij select żeby zmienić tryb gry
	LDA kontroler
	AND #%00100000
	CMP #%00100000
	BNE :++
	
	LDA kontrolerpoprzedni
	AND #%00100000
	CMP #%00000000
	BNE :++
	
	; naciśnięto select
	; wybierz tryb dla 1 gracza lub dla 2 graczy
	
	LDA trybGry
	CMP #$01
	BEQ :+
	
	LDA $0200
	CLC
	ADC #$08
	STA $0200
	
	INC trybGry
	
	JMP :++
:
	
	LDA $0200
	SEC
	SBC #$08
	STA $0200
	
	DEC trybGry
	
:
	
	; kopiuj pamięć z $0200 przez OAMDMA
	LDA #$02
	STA OAMDMA
	
	JMP StanMenuGry
	
StanLadowanieGry:
	
	JSR WylaczPPU
	
	; wyzeruj sprite'y
	LDX #$00
:
	LDA #$FF
	STA $0200, X
	LDA #$00
	INX
	BNE :-
	
	; wybierz paletę tła 1
	LDA #$3F
	STA PPUADDR
	LDA #$05
	STA PPUADDR
	
	; załaduj odpowiednią paletę tła 1 w zależności od trybu gry
	LDA trybGry
	CMP #$00
	BNE :+
	
	; 1 gracz, szara paleta poziomu 0
	LDY #$00
	
	LDA #<PaletyPoziomow
	STA temp
	LDA #>PaletyPoziomow
	STA temp+1
	
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	
	JMP :++
:
	
	; 2 graczy, kolory gracza 1 i 2
	LDA #$0F
	STA PPUDATA
	LDA #$1A
	STA PPUDATA
	LDA #$12
	STA PPUDATA
	
	; załaduj paletę spritów 0 na kolory gracza 1 i 2
	BIT PPUSTATUS
	LDA #$3F
	STA PPUADDR
	LDA #$11
	STA PPUADDR
	
	LDA #$0F
	STA PPUDATA
	LDA #$1A
	STA PPUDATA
	LDA #$12
	STA PPUDATA
	
	; ustaw numer gracza na 2 (zostanie zmieniony po załadowaniu gry na 1)
	INC numerGracza
	
	; losuj pierwszy klocek dla gracza 1
:
	LDA losowa
	AND #%00000111
	CMP #%00000111
	BNE :+
	JSR Losuj
	JMP :-
:
	
	STA numerNastepnegoKlocka1
	
	JSR Losuj
	
	; losuj pierwszy klocek dla gracza 2
:
	LDA losowa
	AND #%00000111
	CMP #%00000111
	BNE :+
	JSR Losuj
	JMP :-
:
	
	STA numerNastepnegoKlocka2
	; stwórz następny klocek drugiemu graczowi bo na początku nic nie widać
	JSR StworzNastepnyKlocek
	
	; załaduj chr bank 1
	LDA #$01
	STA $8000
	
	; narysuj tlo gry na ekranie
	
	; zapisz wskaznik do zmiennej int
	LDA #<GrafikaTloGra
	STA int
	LDA #>GrafikaTloGra
	STA int+1
	
	; wybierz adres w PPU
	BIT PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	; zeruj rejestry i zmienne
	LDX #$00
	LDY #$00
	
	; wczytaj GrafikaTloGra
:
	LDA (int), Y
	STA PPUDATA
	INY
	CPX #$03
	BNE :+
	CPY #$FF
	BEQ :++
:
	CPY #$00
	BNE :--
	INX
	INC int+1
	JMP :--
	
: ; koniec wczytywania grafiki tła gry
	
	; jeżeli tryb dla jednego gracza wyczyść interfejs drugiego gracza
	LDA trybGry
	CMP #$01
	BEQ :++++++
	
	; wybierz miejsce w PPU
	BIT PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$76
	STA PPUADDR
	
	; ustaw rejestry
	LDY #$00
	LDX #$04
	
	; czyść NAST
:
	STY PPUDATA
	DEX
	CPX #$00
	BNE :-
	
	; wybierz miejsce w PPU
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$36
	STA PPUADDR
	
	; ustaw rejestr
	LDX #$05
	
	; czyść PUMKTY
:
	STY PPUDATA
	DEX
	CPX #$00
	BNE :-
	
	; wybierz miejsce w PPU
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$56
	STA PPUADDR
	
	; ustaw rejestr
	LDX #$04
	
	; czyść NNNN
:
	STY PPUDATA
	DEX
	CPX #$00
	BNE :-
	
	; wybierz miejsce w PPU
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$96
	STA PPUADDR
	
	; ustaw rejestr
	LDX #$06
	
	; czyść PUMKTY
:
	STY PPUDATA
	DEX
	CPX #$00
	BNE :-
	
	; wybierz miejsce w PPU
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$B6
	STA PPUADDR
	
	; ustaw rejestr
	LDX #$04
	
	; czyść NNNN
:
	STY PPUDATA
	DEX
	CPX #$00
	BNE :-
	
: ; koniec czyszczenia interfejsu drugiego gracza
	
	JSR WyzerujScrollowanie
	
	LDA #%00010000 ; wybieramy bank 1 z pliku .chr do tla
	STA PPUCTRL
	
	; wlacz sprite i tlo
	LDA #%00011110
	STA PPUMASK
	
	LDA #$00
	STA grajMuzykeMenu
	
	JSR MuzykaGrajMelodie
	
	JSR CzekajNaVBLANK
	
	JMP StanBrakKlocka
	
StanBrakKlocka:
	
	JSR WyzerujScrollowanie
	JSR OdtwarzajMuzyke
	JSR CzekajNaVBLANK
	
	JSR WyswietlLiczbeLinii1
	JSR WyswietlLiczbePunktow1
	
	; linie i punkty drugiego gracza tylko w trybie dla dwóch graczy
	LDA trybGry
	CMP #$00
	BEQ :+
	
	JSR WyswietlLiczbeLinii2
	JSR WyswietlLiczbePunktow2
:
	
	; jeśli tryb na dwóch graczy zmień gracza
	
	LDA trybGry
	CMP #$00
	BEQ :+
	
	INC numerGracza
	LDA numerGracza
	AND #%00000001
	STA numerGracza
	
:
	
	; weź numer następnego klocka
	LDA numerGracza
	CMP #$01
	BEQ :+
	LDA numerNastepnegoKlocka1
	JMP :++
:
	LDA numerNastepnegoKlocka2
:
	STA numerKlocka
	
	; wylosuj następny klocek
	JSR Losuj
:
	LDA losowa
	AND #%00000111
	CMP #%00000111
	BNE :+
	JSR Losuj
	JMP :-
:
	LDX numerGracza
	CPX #$01
	BEQ :+
	STA numerNastepnegoKlocka1
	JMP :++
:
	STA numerNastepnegoKlocka2
:
	
	JSR StworzNastepnyKlocek
	JSR WyzerujScrollowanie
	JSR OdtwarzajMuzyke
	
	JSR CzekajNaVBLANK
	
	JSR StworzKlocek
	JSR RysujKlocek
	JSR WyzerujScrollowanie
	JSR TransferOAMDMA
	JSR OdtwarzajMuzyke
	
	JSR CzekajNaVBLANK
	
	JSR SkopiujMapeKolizji
	JSR SprawdzKolizjeKoniecGry
	
	LDA kolizja
	AND #%10000000
	CMP #%10000000
	BNE :+
	
	; koniec gry
	
	LDA #$4F
	STA temp
	
	JSR MuzykaWylaczWszystkieKanaly
	JSR WyzerujScrollowanie
	JMP StanLadowanieKoniecGry
	
:
	
	JSR WyzerujScrollowanie
	
	; kopiuj pamięć z $0200 przez OAMDMA
	LDA #$02
	STA OAMDMA
	
	JSR CzytajKontroler
	
	JMP StanSpadajacyKlocek
	
StanSpadajacyKlocek:
	
	JSR WyzerujScrollowanie
	JSR CzytajKontroler
	JSR OdtwarzajMuzyke
	JSR Losuj
	JSR RysujKlocek
	JSR SprawdzKolizje
	
	INC zegarSpadania
	
	LDA zegarSpadania
	CMP szybkoscSpadania
	BNE :+
	LDA #$00
	STA zegarSpadania
:
	
	INC zegarCzasGry
	LDA zegarCzasGry
	CMP #$3C
	BNE :+
	
	JSR PoliczSekunde
	LDA #$00
	STA zegarCzasGry
:
	
	JSR CzekajNaVBLANK
	
	; przesuń klocek w dół lub umieść
	
	LDA zegarSpadania
	CMP #$00
	BNE :++
	
	LDA kolizja
	AND #%00000010
	CMP #%00000010
	BEQ :+
	; jeśli pod spodem coś jest to umieść
	; w przeciwnym wypadku przesuń
	JSR PrzesunKlocekWDol
	
	JSR SkopiujMapeKolizji
	JMP StanSpadajacyKlocek
	
:
	
	JMP StanStawianieKlocka
	
:
	
	; dekrementuj zegary kontrolera
	LDA zegarKontrolera
	CMP #$00
	BEQ :+
	DEC zegarKontrolera
:
	LDA zegarKontroleraobrot
	CMP #$00
	BEQ :+
	DEC zegarKontroleraobrot
:
	
	; czy zegar kontrolera pozwala na obrót
	LDA zegarKontroleraobrot
	CMP #$00
	BNE :++
	
	; czy naciśnięto B
	LDA kontroler
	AND #%01000000
	CMP #%01000000
	BNE :+
	
	LDA #$0A
	STA zegarKontroleraobrot
	
	JSR ObrocKlocekWLewo
	JSR SkopiujMapeKolizji
	JMP StanSpadajacyKlocek
	
:
	
	; czy naciśnięto A
	LDA kontroler
	AND #%10000000
	CMP #%10000000
	BNE :+
	
	LDA #$0A
	STA zegarKontroleraobrot
	
	JSR ObrocKlocekWPrawo
	JSR SkopiujMapeKolizji
	JMP StanSpadajacyKlocek
	
:
	
	; czy puszczono A lub B
	LDA kontroler
	AND #%11000000
	CMP #%00000000
	BNE :+
	
	LDA #$00
	STA zegarKontroleraobrot
	
:
	
	LDA zegarKontrolera
	CMP #$00
	BNE :++++++
	
	; czy naciśnięto R
	LDA kontroler
	AND #%00000001
	CMP #%00000001
	BNE :+++
	
	LDA kontrolerpoprzedni
	AND #%00000001
	CMP #%00000000
	BNE :+
	
	; wciśnięto R
	LDA #$0A
	STA zegarKontrolera
	JMP :++
	
:
	; przytrzymano R
	LDA #$04
	STA zegarKontrolera
	
:
	
	JSR PrzesunKlocekWPrawo
	JSR SkopiujMapeKolizji
	JMP StanSpadajacyKlocek
	
:
	
	; czy naciśnięto L
	LDA kontroler
	AND #%00000010
	CMP #%00000010
	BNE :++++
	
	LDA kontrolerpoprzedni
	AND #%00000010
	CMP #%00000000
	BNE :+
	
	; wciśnięto L
	LDA #$0A
	STA zegarKontrolera
	JMP :++
:
	
	; przytrzymano L
	LDA #$04
	STA zegarKontrolera
	
:
	
	JSR PrzesunKlocekWLewo
	JSR SkopiujMapeKolizji
	JMP StanSpadajacyKlocek
	
:
	; duży skok podzielony na dwa małe
	JMP :+++++
:
	
	; czy naciśnięto D
	LDA kontroler
	AND #%00000100
	CMP #%00000100
	BNE :++++
	
	LDA kontrolerpoprzedni
	AND #%00000100
	CMP #%00000000
	BNE :+
	
	; wciśnięto D
	LDA #$0A
	STA zegarKontrolera
	JMP :++
:
	
	; przytrzymano D
	LDA zegarKontroleraszybkosc
	STA zegarKontrolera
	
	CMP #$02
	BEQ :+
	DEC zegarKontroleraszybkosc
	
:
	
	LDA kolizja
	AND #%00000010
	CMP #%00000010
	BEQ :+
	; jeśli pod spodem coś jest to umieść
	; w przeciwnym wypadku przesuń
	JSR PrzesunKlocekWDol
	JSR SkopiujMapeKolizji
	
	JMP StanSpadajacyKlocek
	
:
	
	JMP StanStawianieKlocka
	
:
	
	; czy puszczono L, R lub D
	LDA kontroler
	AND #%00000111
	CMP #%00000000
	BNE :+
	
	LDA #$00
	STA zegarKontrolera
	LDA #$05
	STA zegarKontroleraszybkosc
	
:
	
	; czy naciśnięto Start
	LDA kontroler
	AND #%00010000
	CMP #%00010000
	BNE :+
	
	LDA kontrolerpoprzedni
	AND #%00010000
	CMP #%00000000
	BNE :+
	
	; pauza gry
	JMP StanPauza
	
:
	
	; czy naciśnieto Select
	LDA kontroler
	AND #%00100000
	CMP #%00100000
	BNE :+
	
	LDA kontrolerpoprzedni
	AND #%00100000
	CMP #%00000000
	BNE :+
	
	; następna melodia
	
	JSR MuzykaGrajMelodie
	
:
	
	JSR SkopiujMapeKolizji
	
	; koniec klatki
	
	; kopiuj pamięć z $0200 przez OAMDMA
	LDA #$02
	STA OAMDMA
	
	JMP StanSpadajacyKlocek
	
StanStawianieKlocka:
	
	JSR OdtwarzajMuzyke
	JSR CzekajNaVBLANK
	JSR PostawKlocek
	
	LDA #$00
	STA zegarKontrolera
	STA zegarKontroleraobrot
	LDA #$05
	STA zegarKontroleraszybkosc
	
	; określ numer linii o jeden niżej niż pierwsza rozbijana
	; sprawdź czy będzie usuwana jakaś linia
	
	LDY #$13 ; numer linii którą analizujemy
	
	; pozycja w PPU lewego dolnego rogu planszy - $232A
	; przesuwamy Y do miejsca rozbicia pierwszej linii - 1
:
	
	LDA wypelnienieLinii, Y
	CMP #$00
	BNE :+
	
	JMP StanBrakKlocka
	
:
	
	CMP #$0A
	BEQ :+
	
	DEY
	JMP :--
	
:
	
	; istnieje chociaż jedna linia do rozbicia
	
	INY
	
	STY odczytLinii
	STY zapisLinii
	
	JMP StanAnimacjaRozbijanychLinii
	
StanAnimacjaRozbijanychLinii:
	
	; kopiuj pamięć z $0200 przez OAMDMA
	LDA #$02
	STA OAMDMA
	
	JSR WyzerujScrollowanie
	JSR OdtwarzajMuzyke
	JSR CzekajNaVBLANK
	
	; wypełnij po kolei czarnymi kwadratami linie i napisz na niej tekst
	
	INC klatkaAnimacji
	
	LDA klatkaAnimacji
	CMP #$00
	BNE :++++
	
	LDA #$00
	STA blokAnimacji
	
	JSR WyczyscSpritey
	
	LDX #$00
	LDY odczytLinii
:
	DEY
	LDA wypelnienieLinii, Y
	CMP #$0A
	BNE :+
	
	STY tempY
	
	; stworz sprite w tym miejscu
	CLC
	TYA
	ADC #$06
	ROL
	ROL
	ROL
	TAY
	DEY
	TYA
	STA $0200, X
	INX
	LDA #$80
	STA $0200, X
	INX
	LDA #%00000011
	STA $0200, X
	INX
	LDA #$50
	STA $0200, X
	INX
	
	LDY tempY
	
	INC ileNaRazLinii
	
	JMP :-
	
:
	CMP #$00
	BEQ :+
	
	JMP :--
	
:
	
	JMP StanAnimacjaRozbijanychLinii
	
:
	CMP #$26
	BNE :+
	
	JMP StanAnimacjaRozbijanychLinii
	
:
	CMP #$27
	BNE :+
	
	; koniec animacji, można poczekać chwilkę
	
	JSR OdtworzDzwiekRozbijanejLinii
	
	LDA #$FF
	STA klatkaAnimacji
	
	JSR WyczyscSpritey
	
	JMP StanAktualizacjaPlanszy
	
:
	AND #%00000011
	CMP #%00000011
	BEQ :+
	
	; klatka animacji ++
	
	INC $0201
	INC $0205
	INC $0209
	INC $020D
	
	JMP StanAnimacjaRozbijanychLinii
	
:
	
	; zmień na tekst pod spodem
	
	LDX #$FF
:
	INX
	CPX #$04
	BEQ :+++++++++

	CPX #$00
	BNE :+
	LDA $0200
	JMP :++++
:
	CPX #$01
	BNE :+
	LDA $0204
	JMP :+++
:
	CPX #$02
	BNE :+
	LDA $0208
	JMP :++
:
	LDA $020C
:
	CMP #$FF
	BEQ :-----
	LSR
	LSR
	LSR
	SEC
	SBC #$05
	
	TAY
	
	BIT PPUSTATUS
	LDA PozycjaLiniiWPPUH, Y
	STA PPUADDR
	
	CLC
	LDA PozycjaLiniiWPPUL, Y
	ADC blokAnimacji
	
	STA PPUADDR
	
	LDA klatkaAnimacji
	LSR
	LSR
	TAY
	LDA ileNaRazLinii
	CMP #$01
	BNE :+
	LDA RozbitaLiniaCheemsNapis, Y
:
	CMP #$02
	BNE :+
	LDA RozbitaLiniaDogeNapis, Y
:
	CMP #$03
	BNE :+
	LDA RozbitaLiniaBuffDogeNapis, Y
:
	CMP #$04
	BNE :+
	LDA RozbitaLiniaTemtrisNapis, Y
:
	
	STA PPUDATA
	
	JMP :---------
	
:
	
	; pozycja X ++ i klatka animacji $80
	
	CLC
	LDA $0203
	ADC #$08
	STA $0203
	CLC
	LDA $0207
	ADC #$08
	STA $0207
	CLC
	LDA $020B
	ADC #$08
	STA $020B
	CLC
	LDA $020F
	ADC #$08
	STA $020F
	
	LDA #$80
	STA $0201
	STA $0205
	STA $0209
	STA $020D
	
	INC klatkaAnimacji
	INC blokAnimacji
	
	JMP StanAnimacjaRozbijanychLinii
	
StanAktualizacjaPlanszy: ; przepisz wszystkie rozbijane linie
	
	; kopiuj pamięć z $0200 przez OAMDMA
	LDA #$02
	STA OAMDMA
	
	JSR WyzerujScrollowanie
	JSR OdtwarzajMuzyke
	JSR CzekajNaVBLANK
	
	JSR PrzepiszLinie
	
:
	LDY odczytLinii
	
	LDA wypelnienieLinii, Y
	CMP #$00
	BNE :+
	
	DEC odczytLinii
	
	JMP :+++
	
:
	CMP #$0A
	BNE :+
	
	; ta linia zostanie rozbita, przesuwamy odczyt wyżej
	DEC odczytLinii
	JMP :--
	
:
	
	JMP StanAktualizacjaPlanszy
	
:
	; wyczyść górę planszy tyle linii ile zostało robite, zaaktualizuj zmienną wypelnienieLinii
	
	JSR WyzerujScrollowanie
	JSR CzekajNaVBLANK
	
:
	LDY zapisLinii
	
	BIT PPUDATA
	LDA PozycjaLiniiWPPUH, Y
	STA PPUADDR
	LDA PozycjaLiniiWPPUL, Y
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	
	LDA odczytLinii
	CMP zapisLinii
	BEQ :+
	
	DEC zapisLinii
	JMP :-
	
:
	
	; jeśli zapis z odczytem są równe zakończ pętlę
	
	; oblicz ile linii zostało rozbitych i poprzesuwaj tablice wypelnienieLinii
	
	LDY #$14 ; pozycja odczytu
	LDX #$14 ; pozycja zapisu
	
:
	DEX
:
	DEY
	LDA wypelnienieLinii, Y
	CMP #$0A
	BNE :+
	
	JMP :-
	
:
	
	; jeśli odczyt trafił na brak jakichkolwiek klocków wyskocz z pętli
	CMP #$00
	BEQ :+
	
	LDA wypelnienieLinii, Y
	STA wypelnienieLinii, X
	
	JMP :---
	
:
	
	STX tempX
	
	LDA ileNaRazLinii
	CMP #$01
	BNE :++
	LDA numerGracza
	CMP #$00
	BNE :+
	JSR PoliczLinieCheems1
	JSR PoliczLinieG1
	JMP :++++++++
:
	JSR PoliczLinieCheems2
	JSR PoliczLinieG2
	JMP :+++++++
:
	CMP #$02
	BNE :++
	LDA numerGracza
	CMP #$00
	BNE :+
	JSR PoliczLinieDoge1
	JSR PoliczLinieG1
	JSR PoliczLinieG1
	JMP :++++++
:
	JSR PoliczLinieDoge2
	JSR PoliczLinieG2
	JSR PoliczLinieG2
	JMP :+++++
:
	CMP #$03
	BNE :++
	LDA numerGracza
	CMP #$00
	BNE :+
	JSR PoliczLinieBuffDoge1
	JSR PoliczLinieG1
	JSR PoliczLinieG1
	JSR PoliczLinieG1
	JMP :++++
:
	JSR PoliczLinieBuffDoge2
	JSR PoliczLinieG2
	JSR PoliczLinieG2
	JSR PoliczLinieG2
	JMP :+++
:
	CMP #$04
	BNE :++
	LDA numerGracza
	CMP #$00
	BNE :+
	JSR PoliczLinieTemtris1
	JSR PoliczLinieG1
	JSR PoliczLinieG1
	JSR PoliczLinieG1
	JSR PoliczLinieG1
	JMP :++
:
	JSR PoliczLinieTemtris2
	JSR PoliczLinieG2
	JSR PoliczLinieG2
	JSR PoliczLinieG2
	JSR PoliczLinieG2
:
	JSR CzyNastepnyPoziom
	
	LDA #$00
	STA ileNaRazLinii
	
	LDX tempX
	
	; wyrównaj zapis do odczytu zerując wszystkie śmieci
	TYA
	STA temp
	
	LDA #$00
:
	CPX temp
	BEQ :+
	
	STA wypelnienieLinii, X
	
	DEX
	
	JMP :-
	
:
	
	JMP StanBrakKlocka
	
StanPauza:
	
	JSR CzekajNaVBLANK
	
	LDA #$00
	STA wlaczMuzyke
	STA $4002
	STA $4003
	STA $400A
	STA $400B
	STA $400E
	STA $400F
	
	BIT PPUDATA
	LDA #$20
	STA PPUADDR
	LDA #$6C
	STA PPUADDR
	
	LDA #$0C ; ⏸
	STA PPUDATA
	LDA #$F9 ; P
	STA PPUDATA
	LDA #$EA ; A
	STA PPUDATA
	LDA #$FD ; U
	STA PPUDATA
	LDA #$FF ; Z
	STA PPUDATA
	LDA #$EA ; A
	STA PPUDATA
	
	JSR WyzerujScrollowanie
	
:
	JSR CzytajKontroler
	JSR CzekajNaVBLANK
	
	; czy naciśnięto Start
	LDA kontroler
	AND #%00010000
	CMP #%00010000
	BNE :-
	
	LDA kontrolerpoprzedni
	AND #%00010000
	CMP #%00000000
	BNE :-
	
	; wyłącz pauze
	
	BIT PPUDATA
	LDA #$20
	STA PPUADDR
	LDA #$6C
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA ; ⏸
	STA PPUDATA ; P
	STA PPUDATA ; A
	STA PPUDATA ; U
	STA PPUDATA ; Z
	STA PPUDATA ; A
	
	LDA #%00000111
	STA wlaczMuzyke
	
	JMP StanSpadajacyKlocek
	
StanLadowanieKoniecGry:
	
	JSR CzekajNaVBLANK
	
	; czekaj trochę
	
	DEC temp
	LDA temp
	CMP #$00
	BEQ :+
	
	JMP StanLadowanieKoniecGry
	
:
	
	LDA #$4F
	STA temp
	
	JSR WyzerujScrollowanie
	JSR CzekajNaVBLANK
	
	JSR WylaczPPU
	
	JSR WyczyscSpritey
	
	; załaduj chr bank 0
	LDA #$00
	STA $8000
	
	; narysuj tlo końca gry na ekranie
	
	; zapisz wskaznik do zmiennej int
	LDA #<GrafikaTloKoniecGryKlatka1
	STA int
	LDA #>GrafikaTloKoniecGryKlatka1
	STA int+1
	
	; wybierz adres w PPU
	BIT PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	; zeruj rejestry i zmienne
	LDX #$00
	LDY #$00
	
	; wczytaj GrafikaTloKoniecGryKlatka1
:
	LDA (int), Y
	STA PPUDATA
	INY
	CPX #$03
	BNE :+
	CPY #$FF
	BEQ :++
:
	CPY #$00
	BNE :--
	INX
	INC int+1
	JMP :--
:
	
	JSR WyzerujScrollowanie
	
	LDA #%00010000 ; wybieramy bank 1 z pliku .chr do tla
	STA PPUCTRL
	
	; włącz sprite i tlo
	LDA #%00011110
	STA PPUMASK
	
	LDA #$54
	STA temp
	
	JSR MuzykaGrajKoniecGry
	
	LDA #%00000100
	STA wlaczMuzyke
	
	LDA #$00
	STA odtwarzajMuzykeLosowo
	
	JMP StanKoniecGry
	
StanKoniecGry:
	
	JSR OdtwarzajMuzyke
	JSR CzekajNaVBLANK
	
	; czekaj trochę
	
	DEC temp
	LDA temp
	CMP #$00
	BEQ :+
	
	JMP StanKoniecGry
	
:
	
	JSR WylaczPPU
	
	; załaduj chr bank 0
	LDA #$00
	STA $8000
	
	; narysuj tlo końca gry klatka 2 na ekranie
	
	; zapisz wskaznik do zmiennej int
	LDA #<GrafikaTloKoniecGryKlatka2
	STA int
	LDA #>GrafikaTloKoniecGryKlatka2
	STA int+1
	
	; wybierz adres w PPU
	BIT PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	; zeruj rejestry i zmienne
	LDX #$00
	LDY #$00
	
	; wczytaj GrafikaTloKoniecGryKlatka2
:
	LDA (int), Y
	STA PPUDATA
	INY
	CPX #$03
	BNE :+
	CPY #$FF
	BEQ :++
:
	CPY #$00
	BNE :--
	INX
	INC int+1
	JMP :--
:
	
	; wypisz punkty na ekran
	
	LDA trybGry
	CMP #$01
	BEQ :+
	
	JSR WyswietlStatystki
	JMP :++
:
	JSR WyswietlStatystki2Graczy
:
	
	JSR WyzerujScrollowanie
	
	LDA #%00010000 ; wybieramy bank 1 z pliku .chr do tla
	STA PPUCTRL
	
	; wlacz sprite i tlo
	LDA #%00011110
	STA PPUMASK
	
	JMP StanCzekajNaReset
	
StanCzekajNaReset:
	
	JSR CzytajKontroler
	JSR CzekajNaVBLANK
	JSR OdtwarzajMuzyke
	
	LDA kontroler
	AND #%00010000
	CMP #%00010000
	BNE :+
	
	JMP LadowanieMenu
	
:
	
	JMP StanCzekajNaReset

; =========================================================
; ====================== podprogramy ======================
; =========================================================

WylaczPPU:

	LDA #$40
	STA PPUCTRL
	STA PPUMASK
	
	RTS

ZerujAPU:
	
	; inizjalizuj $4000-4013
	LDY #$13
	
:
	LDA ZerowanieAPU, Y
	STA $4000, Y
	DEY
	BPL :-
	
	LDA #$0F
	STA APUSTATUS
	
	RTS
	
WyzerujScrollowanie:
	
	; wyzeruj scrollowanie
	LDA #$00
	STA PPUSCROLL
	STA PPUSCROLL
	
	LDA #%00010000 ; wybieramy bank 1 z pliku .chr do tla
	STA PPUCTRL
	
	RTS
	
CzekajNaVBLANK:
	
:
	BIT PPUSTATUS
	BPL :-
	
	RTS
	
TransferOAMDMA:

	LDA #$02
	STA OAMDMA
	
	RTS
	
GitHubUstawPaleteRozjasnij:
	
	INC $FF
	
	LDY tempY
	
	BIT PPUSTATUS
	LDA #$3F
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	LDX #$00
:
	LDA GitHubPalety, Y
	STA PPUDATA
	INY
	INX
	CPX #$08
	BNE :-
	
	STY tempY
	
	RTS
	
WyczyscSpritey:
	
	LDA #$FF
	STA $0200
	STA $0201
	STA $0202
	STA $0203
	STA $0204
	STA $0205
	STA $0206
	STA $0207
	STA $0208
	STA $0209
	STA $020A
	STA $020B
	STA $020C
	STA $020D
	STA $020E
	STA $020F
	
	RTS
	
CzytajKontroler:
	
	; skopiuj wartości do zmiennej kontrolerpoprzedni
	
	LDA kontroler
	STA kontrolerpoprzedni
	LDA #$00
	STA kontroler
	
	LDY numerGracza
	
	; odczyt z wejścia
	
    LDA #$01
    STA JOYPAD1
    STA kontroler
    LSR A
    STA JOYPAD1
:
    LDA JOYPAD1, Y
    LSR A
    ROL kontroler
    BCC :-
	
	RTS
	
; ================ generator liczb losowych ===============

Losuj:
	
	LDX #$08
	LDA losowa
:
	ASL
	ROL losowa+1
	BCC :+
	EOR #$2D
:
	DEX
	BNE :--
	STA losowa
	CMP #$00
	
	RTS

; ================== dodatkowe obliczenia =================

ObliczPozycjeWPPU:
	
	; odczyt pozycji Y
	LDA pozycjaKlockaY
	CLC
	ADC #$01
	STA pozycjaPPUH
	INC pozycjaPPUH
	LDA pozycjaPPUH
	LSR A
	LSR A
	LSR A
	STA pozycjaPPUH
	
	; odczyt pozycji X
	LDA pozycjaKlockaX
	SEC
	SBC #$08
	LSR A
	LSR A
	LSR A
	STA pozycjaPPUL
	
	LDA #$00
	LDX pozycjaPPUH
	LDY #$20
	
	; obliczenia
:
	CPX #$00
	BEQ :++
	CLC
	ADC #$20
	BCS :+
	DEX
	JMP :-
:
	DEX
	INY
	JMP :--
	
:
	
	CLC
	ADC pozycjaPPUL
	BCS :+
	JMP :++
:
	INY
:
	
	STY pozycjaPPUH
	STA pozycjaPPUL
	
	RTS
	
ObliczWskaznikDoDanychKlocka:
	
	LDA #<DaneKlockow
	STA pozycjaDanychKlocka
	LDA #>DaneKlockow
	STA pozycjaDanychKlocka+1
	
	CLC
	LDA numerKlocka
	ROL A
	TAY
	LDA (pozycjaDanychKlocka), Y
	STA temp
	INY
	LDA (pozycjaDanychKlocka), Y
	STA temp+1
	
	CLC
	LDA obrotKlocka
	AND #%00000011
	ROL A
	TAY
	LDA (temp), Y
	STA pozycjaDanychKlocka
	INY
	LDA (temp), Y
	STA pozycjaDanychKlocka+1
	
	RTS
	
; ===================== ruch klockiem =====================
	
PrzesunKlocekWLewo:
	
	; sprawdź kolizje
	
	LDA kolizja
	AND #%00000100
	CMP #%00000100
	BNE :+
	RTS
:
	
	LDA pozycjaKlockaX
	SEC
	SBC #$08
	STA pozycjaKlockaX
	
	RTS
	
PrzesunKlocekWDol:
	
	; sprawdź kolizje
	
	LDA kolizja
	AND #%00000010
	CMP #%00000010
	BNE :+
	RTS
:
	
	CLC
	LDA pozycjaKlockaY
	ADC #$08
	STA pozycjaKlockaY
	
	LDA #$00
	STA zegarSpadania
	
	INC pozycjaLiniiKlocka
	
	RTS
	
PrzesunKlocekWPrawo:
	
	; sprawdź kolizje
	
	LDA kolizja
	AND #%00000001
	CMP #%00000001
	BNE :+
	RTS
:
	
	CLC
	LDA pozycjaKlockaX
	ADC #$08
	STA pozycjaKlockaX
	
	RTS
	
ObrocKlocekWPrawo:
	; Zgodnie ze wskazówkami zegara
	
	; sprawdź kolizje
	
	LDA kolizja
	AND #%00001000
	CMP #%00001000
	BNE :++
	
	LDA kolizja
	AND #%00100001
	CMP #%00000001
	BNE :+
	
	JSR PrzesunKlocekWLewo
	INC obrotKlocka
	
:
	RTS
:
	
	INC obrotKlocka
	
	RTS
	
ObrocKlocekWLewo:
	; Przeciwnie do ruchu wskazówek zegara
	
	; sprawdź kolizje
	
	LDA kolizja
	AND #%00010000
	CMP #%00010000
	BNE :++
	
	LDA kolizja
	AND #%01000001
	CMP #%00000001
	BNE :+
	
	JSR PrzesunKlocekWLewo
	DEC obrotKlocka
	
:
	RTS
:
	
	DEC obrotKlocka
	
	RTS
	
; =================== tworzenie klocków ===================
	
StworzKlocek:
	
	LDA trybGry
	CMP #$01
	BEQ :+
	
	; zmień paletę
	
	LDA #<DaneKlockowPalety
	STA temp
	LDA #>DaneKlockowPalety
	STA temp+1
	
	CLC
	LDA numerKlocka
	ROL A
	ROL A
	TAY
	
	; załaduj palety ($3F10)
	
	BIT PPUSTATUS
	LDA #$3F
	STA PPUADDR
	LDA #$10
	STA PPUADDR
	
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	
:
	
	; wyzeruj pozycje
	
	LDA #$2F
	STA pozycjaKlockaY
	LDA #$68
	STA pozycjaKlockaX
	
	LDA #$00
	STA obrotKlocka
	
	STA pozycjaLiniiKlocka
	
	RTS
	
StworzNastepnyKlocek:
	
	; ustawienie w int następnego klocka uwzględniając graczy
	LDA numerGracza
	CMP #$01
	BEQ :+
	LDA numerNastepnegoKlocka1
	JMP :++
:
	LDA numerNastepnegoKlocka2
:
	STA int
	
	; zmień paletę
	
	LDA #<DaneKlockowPalety
	STA temp
	LDA #>DaneKlockowPalety
	STA temp+1
	
	CLC
	LDA int
	ROL A
	ROL A
	TAY
	
	LDA numerGracza
	CMP #$01
	BEQ :+
	; załaduj paletę spriteów 1 ($3F14)
	LDA #$3F
	STA PPUADDR
	LDA #$14
	STA PPUADDR
	JMP :++
:
	; załaduj paletę spriteów 2 ($3F18)
	LDA #$3F
	STA PPUADDR
	LDA #$18
	STA PPUADDR
:
	
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	LDA (temp), Y
	STA PPUDATA
	INY
	
	LDA #<DaneKlockow
	STA pozycjaDanychNastepnegoKlocka
	LDA #>DaneKlockow
	STA pozycjaDanychNastepnegoKlocka+1
	
	CLC
	LDA int
	ROL A
	TAY
	LDA (pozycjaDanychNastepnegoKlocka), Y
	STA temp
	INY
	LDA (pozycjaDanychNastepnegoKlocka), Y
	STA temp+1
	
	LDY #$00
	LDA (temp), Y
	STA pozycjaDanychNastepnegoKlocka
	INY
	LDA (temp), Y
	STA pozycjaDanychNastepnegoKlocka+1
	
	; stwórz sprite'y
	
	LDA #$28
	STA temp+1
	LDA #$18
	STA temp
	
	LDX #$00 ; pozycja w OAM ($0210)
	LDY #$FF ; pozycja w DanychKlocków
	
:
	INY
	CPY #$10
	BEQ :++++
	
	CLC
	LDA temp
	ADC #$08
	STA temp
	
	LDA temp
	CMP #$40
	BNE :+
	
	LDA #$20
	STA temp
	
	CLC
	LDA temp+1
	ADC #$08
	STA temp+1
	
:
	
	LDA (pozycjaDanychNastepnegoKlocka), Y
	CMP #$00
	BEQ :--
	
	LDA numerGracza
	CMP #$01
	BEQ :+
	
	; tworzenie spritów klocka gracza 1
	
	; ustaw pozycję Y
	LDA temp+1
	STA $0210, X
	INX
	LDA (pozycjaDanychNastepnegoKlocka), Y
	STA $0210, X
	INX
	LDA #$01
	STA $0210, X
	INX
	; ustaw pozycję X
	LDA temp
	STA $0210, X
	INX
	
	JMP :++
:
	
	; tworzenie spritów klocka gracza 2
	
	; ustaw pozycję Y
	LDA temp+1
	STA $0220, X
	INX
	LDA (pozycjaDanychNastepnegoKlocka), Y
	STA $0220, X
	INX
	LDA #$02
	STA $0220, X
	INX
	; ustaw pozycję X
	LDA temp
	ADC #$90
	STA $0220, X
	INX
	
:
	
	JMP :----
	
:
	
	JSR TransferOAMDMA
	
	RTS
	
; ====================== rysuj klocek =====================
	
RysujKlocek:
	
	JSR ObliczWskaznikDoDanychKlocka
	
	LDA pozycjaKlockaX
	SEC
	SBC #$08
	STA temp
	LDA pozycjaKlockaY
	STA temp+1
	
	; stwórz sprite'y
	
	LDA #$FF
	STA int ; mod 4
	
	LDX #$00 ; wskaźnik na OAM ($0200)
	LDY #$FF ; wskaźnik na DaneKlocków
	
	; może i nie optymalnie ale działa
	
:
	INY
:
	INC int
	CPY #$10
	BEQ :+++
	
	LDA int
	CMP #$04
	BNE :+
	
	LDA #$FF
	STA int
	
	LDA temp
	SEC
	SBC #$20
	STA temp
	
	CLC
	LDA temp+1
	ADC #$08
	STA temp+1
	
	JMP :-
	
:
	
	CLC
	LDA temp
	ADC #$08
	STA temp
	
	LDA (pozycjaDanychKlocka), Y
	CMP #$00
	BEQ :---
	
	; zapisz pozycje Y
	LDA temp+1
	STA $0200, X
	INX
	LDA (pozycjaDanychKlocka), Y
	
	; załaduj sprite w zależności od numeru gracza
	
	STY tempY
	LDY trybGry
	CPY #$00
	BEQ :+
	CLC
	ADC #$10
	LDY numerGracza
	CPY #$00
	BEQ :+
	CLC
	ADC #$10
:
	LDY tempY
	
	STA $0200, X
	INX
	; zapisz informacje o lustrze i palecie
	LDA #$00
	STA $0200, X
	INX
	; zapisz pozycje X
	LDA temp
	STA $0200, X
	INX
	
	JMP :----
	
:
	
	RTS
	
; ==================== stawianie klocka ===================
	
PostawKlocek:
	
	; odtwórz dźwięk
	
	LDA #%01011111
	STA $4004
	LDA #%11111111
	STA $4005
	LDA #%00000000
	STA $4006
	LDA #%01111111
	STA $4007
	
	LDA pozycjaPPUH
	STA temp
	LDA pozycjaPPUL
	STA temp+1
	
	DEC pozycjaLiniiKlocka
	
	CLC
	INC temp+1
	ADC #$01
	STA temp+1
	LDA temp
	ADC #$00
	STA temp
	
	; przepisz tę samą liczbę jako tło
	
	LDA #$FF
	STA int ; mod 4
	
	LDY #$FF ; miejsce w danych klocków
	LDX #$00 ; miejsce w mapie kolizji
	
	BIT PPUSTATUS
	LDA temp
	STA PPUADDR
	LDA temp+1
	STA PPUADDR
	
:
	INC int
	INX
	INY
	
	CPY #$10
	BEQ :++++
	
	LDA int
	CMP #$04
	BNE :+
	
	LDA #$00
	STA int
	
	INC pozycjaLiniiKlocka
	
	; przesuń na następny rząd
	
	CLC
	LDA temp+1
	ADC #$20
	STA temp+1
	LDA temp
	ADC #$00
	STA temp
	
	BIT PPUSTATUS
	LDA temp
	STA PPUADDR
	LDA temp+1
	STA PPUADDR
	
	INX
	INX
	
:
	
	LDA (pozycjaDanychKlocka), Y
	CMP #$00
	BNE :+
	LDA mapaKolizji, X
	STA PPUDATA ; przepisz bajt z mapy kolizji (nie akutalizuj tła)
	JMP :--
:
	
	; jeśli tryb dla dwóch graczy inaczej zachowuje się tło
	STY tempY ; tymczasowo przechowaj Y
	LDY trybGry
	CPY #$00
	BEQ :+
	CLC
	ADC #$10
	LDY numerGracza
	CPY #$00
	BEQ :+
	CLC
	ADC #$10
:
	
	STA PPUDATA ; przepisz bajt z danych klocków (aktualizuj tło)
	LDY tempY
	
	; dodaj bloki do zmiennej zajętośćPlanszy
	
	TXA
	LDX pozycjaLiniiKlocka
	INX
	INC wypelnienieLinii, X
	TAX
	
	JMP :----
	
:
	
	JSR WyczyscSpritey
	
	LDA #$00
	STA zegarSpadania
	
	RTS
	
; ================== sprawdzanie kolizji ==================
	
SprawdzKolizje:
	
	; zeruj wykrywanie kolizji
	LDA #%00000000 ; %XYZBALDP kolizja - X - koniec gry, Y - kolizja po obrocie w prawo z przesunieciem, Z - kolizja po obrocie w lewo z przesunieciem, B - przy obrocie w lewo, A - przy obrocie w prawo, L - z lewej, D - z dołu, P - z prawej)
	STA kolizja
	
	; sprawdzanie kolizji z lewej strony
	
	LDX #$FF ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (pozycjaDanychKlocka), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%00000100
	STA kolizja
	
:
	
	; sprawdzanie kolizji u dołu
	
	LDX #$06 ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (pozycjaDanychKlocka), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%00000010
	STA kolizja
	
:
	
	; sprawdzanie kolizji z prawej strony
	
	LDX #$01 ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (pozycjaDanychKlocka), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%00000001
	STA kolizja
	
:
	
	; sprawdzanie kolizji po obrocie zgodnie z ruchem wskazówek
	
	LDA pozycjaDanychKlocka
	STA int
	LDA pozycjaDanychKlocka+1
	STA int+1
	
	LDA obrotKlocka
	AND #%00000011
	CMP #%00000011
	BNE :+
	
	LDA int
	SEC
	SBC #$30
	STA int
	LDA int+1
	SBC #$00
	STA int+1
	JMP :++
	
:
	
	CLC
	LDA int
	ADC #$10
	STA int
	LDA int+1
	ADC #$00
	STA int+1
	
:
	
	LDX #$00 ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (int), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%00001000
	STA kolizja
	
:
	
	; sprawdzanie kolizji po obrocie przeciwnie do ruchu wskazówek
	
	LDA pozycjaDanychKlocka
	STA int
	LDA pozycjaDanychKlocka+1
	STA int+1
	
	LDA obrotKlocka
	AND #%00000011
	CMP #%00000000
	BNE :+
	
	CLC
	LDA int
	ADC #$30
	STA int
	LDA int+1
	ADC #$00
	STA int+1
	JMP :++
	
:
	
	LDA int
	SEC
	SBC #$10
	STA int
	LDA int+1
	SBC #$00
	STA int+1
	
:
	
	LDX #$00 ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (int), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%00010000
	STA kolizja
	
:
	
	; sprawdzanie kolizji po obrocie zgodnie z ruchem wskazówek z przesunięciem
	
	LDA pozycjaDanychKlocka
	STA int
	LDA pozycjaDanychKlocka+1
	STA int+1
	
	LDA obrotKlocka
	AND #%00000011
	CMP #%00000011
	BNE :+
	
	LDA int
	SEC
	SBC #$30
	STA int
	LDA int+1
	SBC #$00
	STA int+1
	JMP :++
	
:
	
	CLC
	LDA int
	ADC #$10
	STA int
	LDA int+1
	ADC #$00
	STA int+1
	
:
	
	LDX #$FF ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (int), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%00100000
	STA kolizja
	
:
	
	; sprawdzanie kolizji po obrocie przeciwnie do ruchu wskazówek z przesunięciem
	
	LDA pozycjaDanychKlocka
	STA int
	LDA pozycjaDanychKlocka+1
	STA int+1
	
	LDA obrotKlocka
	AND #%00000011
	CMP #%00000011
	BNE :+
	
	LDA int
	SEC
	SBC #$30
	STA int
	LDA int+1
	SBC #$00
	STA int+1
	JMP :++
	
:
	
	CLC
	LDA int
	ADC #$10
	STA int
	LDA int+1
	ADC #$00
	STA int+1
	
:
	
	LDX #$FF ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (int), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%01000000
	STA kolizja
	
:
	
	RTS
	
SprawdzKolizjeKoniecGry:
	
	; zeruj wykrywanie kolizji
	LDA kolizja
	AND #%01111111 ; koniec gry (1), niewykorzystane (3), obrót w lewo (1), obrót w prawo (1), lewa (1), dół (1), prawa (1)
	STA kolizja
	
	; sprawdzanie kolizji pod klockiem
	
	LDX #$00 ; miejsce w mapie kolizji
	LDY #$FF ; miejsce w danych klocków
	LDA #$FF
	STA temp ; mod 4
	
:
	INX
	INY
	INC temp
	
	LDA temp
	CMP #$04
	BNE :+
	
	LDA #$00
	STA temp
	INX
	INX
	
:
	CPY #$10
	BEQ :+
	
	LDA (pozycjaDanychKlocka), Y
	CMP #$00
	BEQ :--
	
	LDA mapaKolizji, X
	CMP #$00
	BEQ :--
	
	LDA kolizja
	ORA #%10000000
	STA kolizja
	
:
	
	RTS
	
SkopiujMapeKolizji:
	
	JSR ObliczPozycjeWPPU
	
	LDA pozycjaPPUH
	STA temp
	LDA pozycjaPPUL
	STA temp+1
	
	; skopiuj siatkę kolizji
	
	BIT PPUSTATUS
	LDA temp
	STA PPUADDR
	LDA temp+1
	STA PPUADDR
	BIT PPUDATA ; pierwszy odczyt jest niepoprawny i na złej pozycji
	
	LDY #$00
	
	; odczytaj tablicę 6 x 5 bajtów
	
:
	LDX #$00
:
	
	LDA PPUDATA
	STA mapaKolizji, Y
	
	INY
	INX
	CPX #$06
	BNE :-
	
	; przesuń do następnego rzędu
	CLC
	LDA temp+1
	ADC #$20
	STA temp+1
	LDA temp
	ADC #$00
	STA temp
	
	BIT PPUSTATUS
	LDA temp
	STA PPUADDR
	LDA temp+1
	STA PPUADDR
	BIT PPUDATA
	
	CPY #$1E
	BNE :--
	
	RTS
	
; ================== przepisywanie linii ==================
	
PrzepiszLinie:
	
	; przepisz linię z odczytu do tymczasowej
	
	LDY odczytLinii
	
	BIT PPUDATA
	LDA PozycjaLiniiWPPUH, Y
	STA PPUADDR
	LDA PozycjaLiniiWPPUL, Y
	STA PPUADDR
	BIT PPUDATA
	
	LDX #$FF ; pozycja w odczycie linii
	
:
	INX
	CPX #$0A
	BEQ :+
	LDA PPUDATA
	STA zrzutLinii, X
	JMP :-
:
	
	LDA wypelnienieLinii-1, Y
	CMP #$0A
	BNE :++
	
	LDA trybGry
	CMP #$01
	BEQ :+
	
	JSR ZmienGrafikeRozbitaGora
	JMP :++
:
	JSR ZmienGrafikeRozbitaGoraG1
	JSR ZmienGrafikeRozbitaGoraG2
:
	LDA wypelnienieLinii+1, Y
	CMP #$0A
	BNE :++
	
	LDA trybGry
	CMP #$01
	BEQ :+
	
	JSR ZmienGrafikeRozbitaDol
	JMP :++
:
	JSR ZmienGrafikeRozbitaDolG1
	JSR ZmienGrafikeRozbitaDolG2
:
	
	; przepisz tymczasową na zapis
	
	LDY zapisLinii
	
	BIT PPUDATA
	LDA PozycjaLiniiWPPUH, Y
	STA PPUADDR
	LDA PozycjaLiniiWPPUL, Y
	STA PPUADDR
	
	LDX #$FF ; pozycja w zapisie linii
	
:
	INX
	CPX #$0A
	BEQ :+
	LDA zrzutLinii, X
	STA PPUDATA
	JMP :-
:
	
	DEC odczytLinii
	DEC zapisLinii
	
	RTS
	
ZmienGrafikeRozbitaGora:
	
	LDX #$FF
	
:
	INX
	CPX #$0A
	BNE :+
	RTS
:
	
	; zamień wygląd klocków
	LDA zrzutLinii, X
	; 14 -> 10
	CMP #$14
	BNE :+
	LDA #$10
	STA zrzutLinii, X
	JMP :--
:   
	; 16 -> 13
	CMP #$16
	BNE :+
	LDA #$13
	STA zrzutLinii, X
	JMP :---
:
	; 19 -> 12
	CMP #$19
	BNE :+
	LDA #$12
	STA zrzutLinii, X
	JMP :----
:
	; 1A -> 11
	CMP #$1A
	BNE :+
	LDA #$11
	STA zrzutLinii, X
	JMP :-----
:
	; 1C -> 18
	CMP #$1C
	BNE :+
	LDA #$18
	STA zrzutLinii, X
	JMP :------
:
	; 1D -> 15
	CMP #$1D
	BNE :+
	LDA #$15
	STA zrzutLinii, X
	JMP :-------
:
	; 1E -> 17
	CMP #$1E
	BNE :+
	LDA #$17
	STA zrzutLinii, X
	JMP :--------
:
	; 1F -> 1B
	CMP #$1F
	BNE :+
	LDA #$1B
	STA zrzutLinii, X
	JMP :---------
:
	
	JMP :----------
	
ZmienGrafikeRozbitaGoraG1:
	
	LDX #$FF
	
:
	INX
	CPX #$0A
	BNE :+
	RTS
:
	
	; zamień wygląd klocków
	LDA zrzutLinii, X
	; 24 -> 20
	CMP #$24
	BNE :+
	LDA #$20
	STA zrzutLinii, X
	JMP :--
:   
	; 26 -> 23
	CMP #$26
	BNE :+
	LDA #$23
	STA zrzutLinii, X
	JMP :---
:
	; 29 -> 22
	CMP #$29
	BNE :+
	LDA #$22
	STA zrzutLinii, X
	JMP :----
:
	; 2A -> 21
	CMP #$2A
	BNE :+
	LDA #$21
	STA zrzutLinii, X
	JMP :-----
:
	; 2C -> 28
	CMP #$2C
	BNE :+
	LDA #$28
	STA zrzutLinii, X
	JMP :------
:
	; 2D -> 25
	CMP #$2D
	BNE :+
	LDA #$25
	STA zrzutLinii, X
	JMP :-------
:
	; 2E -> 27
	CMP #$2E
	BNE :+
	LDA #$27
	STA zrzutLinii, X
	JMP :--------
:
	; 2F -> 2B
	CMP #$2F
	BNE :+
	LDA #$2B
	STA zrzutLinii, X
	JMP :---------
:
	
	JMP :----------
	
ZmienGrafikeRozbitaGoraG2:
	
	LDX #$FF
	
:
	INX
	CPX #$0A
	BNE :+
	RTS
:
	
	; zamień wygląd klocków
	LDA zrzutLinii, X
	; 34 -> 30
	CMP #$34
	BNE :+
	LDA #$30
	STA zrzutLinii, X
	JMP :--
:   
	; 36 -> 33
	CMP #$36
	BNE :+
	LDA #$33
	STA zrzutLinii, X
	JMP :---
:
	; 39 -> 32
	CMP #$39
	BNE :+
	LDA #$32
	STA zrzutLinii, X
	JMP :----
:
	; 3A -> 31
	CMP #$3A
	BNE :+
	LDA #$31
	STA zrzutLinii, X
	JMP :-----
:
	; 3C -> 38
	CMP #$3C
	BNE :+
	LDA #$38
	STA zrzutLinii, X
	JMP :------
:
	; 3D -> 35
	CMP #$3D
	BNE :+
	LDA #$35
	STA zrzutLinii, X
	JMP :-------
:
	; 3E -> 37
	CMP #$3E
	BNE :+
	LDA #$37
	STA zrzutLinii, X
	JMP :--------
:
	; 3F -> 3B
	CMP #$3F
	BNE :+
	LDA #$3B
	STA zrzutLinii, X
	JMP :---------
:
	
	JMP :----------
	
ZmienGrafikeRozbitaDol:
	
	LDX #$FF
	
:
	INX
	CPX #$0A
	BNE :+
	RTS
:
	
	; zamień wygląd klocków
	LDA zrzutLinii, X
	; 13 -> 10
	CMP #$13
	BNE :+
	LDA #$10
	STA zrzutLinii, X
	JMP :--
:   
	; 16 -> 14
	CMP #$16
	BNE :+
	LDA #$14
	STA zrzutLinii, X
	JMP :---
:
	; 17 -> 11
	CMP #$17
	BNE :+
	LDA #$11
	STA zrzutLinii, X
	JMP :----
:
	; 18 -> 12
	CMP #$18
	BNE :+
	LDA #$12
	STA zrzutLinii, X
	JMP :-----
:
	; 1B -> 15
	CMP #$1B
	BNE :+
	LDA #$15
	STA zrzutLinii, X
	JMP :------
:
	; 1C -> 19
	CMP #$1C
	BNE :+
	LDA #$19
	STA zrzutLinii, X
	JMP :-------
:
	; 1E -> 1A
	CMP #$1E
	BNE :+
	LDA #$1A
	STA zrzutLinii, X
	JMP :--------
:
	; 1F -> 1D
	CMP #$1F
	BNE :+
	LDA #$1D
	STA zrzutLinii, X
	JMP :---------
:
	
	JMP :----------
	
ZmienGrafikeRozbitaDolG1:
	
	LDX #$FF
	
:
	INX
	CPX #$0A
	BNE :+
	RTS
:
	
	; zamień wygląd klocków
	LDA zrzutLinii, X
	; 23 -> 20
	CMP #$23
	BNE :+
	LDA #$20
	STA zrzutLinii, X
	JMP :--
:   
	; 26 -> 24
	CMP #$26
	BNE :+
	LDA #$24
	STA zrzutLinii, X
	JMP :---
:
	; 27 -> 21
	CMP #$27
	BNE :+
	LDA #$21
	STA zrzutLinii, X
	JMP :----
:
	; 28 -> 22
	CMP #$28
	BNE :+
	LDA #$22
	STA zrzutLinii, X
	JMP :-----
:
	; 2B -> 25
	CMP #$2B
	BNE :+
	LDA #$25
	STA zrzutLinii, X
	JMP :------
:
	; 2C -> 29
	CMP #$2C
	BNE :+
	LDA #$29
	STA zrzutLinii, X
	JMP :-------
:
	; 2E -> 2A
	CMP #$2E
	BNE :+
	LDA #$2A
	STA zrzutLinii, X
	JMP :--------
:
	; 2F -> 2D
	CMP #$2F
	BNE :+
	LDA #$2D
	STA zrzutLinii, X
	JMP :---------
:
	
	JMP :----------
	
ZmienGrafikeRozbitaDolG2:
	
	LDX #$FF
	
:
	INX
	CPX #$0A
	BNE :+
	RTS
:
	
	; zamień wygląd klocków
	LDA zrzutLinii, X
	; 33 -> 30
	CMP #$33
	BNE :+
	LDA #$30
	STA zrzutLinii, X
	JMP :--
:   
	; 36 -> 34
	CMP #$36
	BNE :+
	LDA #$34
	STA zrzutLinii, X
	JMP :---
:
	; 37 -> 31
	CMP #$37
	BNE :+
	LDA #$31
	STA zrzutLinii, X
	JMP :----
:
	; 38 -> 32
	CMP #$38
	BNE :+
	LDA #$32
	STA zrzutLinii, X
	JMP :-----
:
	; 3B -> 35
	CMP #$3B
	BNE :+
	LDA #$35
	STA zrzutLinii, X
	JMP :------
:
	; 3C -> 39
	CMP #$3C
	BNE :+
	LDA #$39
	STA zrzutLinii, X
	JMP :-------
:
	; 3E -> 3A
	CMP #$3E
	BNE :+
	LDA #$3A
	STA zrzutLinii, X
	JMP :--------
:
	; 3F -> 3D
	CMP #$3F
	BNE :+
	LDA #$3D
	STA zrzutLinii, X
	JMP :---------
:
	
	JMP :----------
	
; =========================================================
; ================ liczenie punktów i linii ===============
; =========================================================
	
PoliczLinieG1:
	
	INC liczbaLiniiNastepnyPoziom
	INC liczbaLinii1BCD+3
	
	LDX #$03
	
:
	LDA liczbaLinii1BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA liczbaLinii1BCD, X
	DEX
	INC liczbaLinii1BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieG2:
	
	INC liczbaLiniiNastepnyPoziom
	INC liczbaLinii2BCD+3
	
	LDX #$03
	
:
	LDA liczbaLinii2BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA liczbaLinii2BCD, X
	DEX
	INC liczbaLinii2BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
WyswietlLiczbeLinii1:
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$44
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC liczbaLinii1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	RTS
	
WyswietlLiczbeLinii2:
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$56
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC liczbaLinii2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	RTS
	
PoliczPunktG1:
	
	INC punkty1BCD+3
	
	LDX #$03
	
:
	LDA punkty1BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA punkty1BCD, X
	DEX
	INC punkty1BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczPunktG2:
	
	INC punkty2BCD+3
	
	LDX #$03
	
:
	LDA punkty2BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA punkty2BCD, X
	DEX
	INC punkty2BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
WyswietlLiczbePunktow1:
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$A4
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC punkty1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	RTS
	
WyswietlLiczbePunktow2:
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$B6
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC punkty2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	RTS
	
PoliczLinieCheems1:
	
	JSR PoliczPunktG1
	
	INC linieCheems1BCD+3
	
	LDX #$03
	
:
	LDA linieCheems1BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieCheems1BCD, X
	DEX
	INC linieCheems1BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieCheems2:
	
	JSR PoliczPunktG2
	
	INC linieCheems2BCD+3
	
	LDX #$03
	
:
	LDA linieCheems2BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieCheems2BCD, X
	DEX
	INC linieCheems2BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieDoge1:
	
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	
	INC linieDoge1BCD+3
	
	LDX #$03
	
:
	LDA linieDoge1BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieDoge1BCD, X
	DEX
	INC linieDoge1BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieDoge2:
	
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	
	INC linieDoge2BCD+3
	
	LDX #$03
	
:
	LDA linieDoge2BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieDoge2BCD, X
	DEX
	INC linieDoge2BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieBuffDoge1:
	
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	
	INC linieBuffDoge1BCD+3
	
	LDX #$03
	
:
	LDA linieBuffDoge1BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieBuffDoge1BCD, X
	DEX
	INC linieBuffDoge1BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieBuffDoge2:
	
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	
	INC linieBuffDoge2BCD+3
	
	LDX #$03
	
:
	LDA linieBuffDoge2BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieBuffDoge2BCD, X
	DEX
	INC linieBuffDoge2BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieTemtris1:
	
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	JSR PoliczPunktG1
	
	INC linieTemtris1BCD+3
	
	LDX #$03
	
:
	LDA linieTemtris1BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieTemtris1BCD, X
	DEX
	INC linieTemtris1BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
PoliczLinieTemtris2:
	
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	JSR PoliczPunktG2
	
	INC linieTemtris2BCD+3
	
	LDX #$03
	
:
	LDA linieTemtris2BCD, X
	CMP #$0A
	BNE :+
	
	LDA #$00
	STA linieTemtris2BCD, X
	DEX
	INC linieTemtris2BCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :-
:
	
	RTS
	
WyswietlStatystki:
	
	; pumkty
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$CB
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC punkty1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; linie ogółem
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$0B
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC liczbaLinii1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość cheems
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$4B
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieCheems1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość doge
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8B
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieDoge1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość buffdoge
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$CB
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieBuffDoge1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość temtris
	
	BIT PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$0B
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieTemtris1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; czas gry
	
	BIT PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$4B
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC czasGryBCD, X
	STA PPUDATA
	
	INX
	CPX #$03
	BNE :+
	
	BIT PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$4F
	STA PPUADDR
	
	JMP :-
:
	CPX #$05
	BEQ :+
	JMP :--
:
	
	RTS
	
WyswietlStatystki2Graczy:
	
	; sprawdź kto ma więcej punktów
	
	LDA #$01
	STA temp
	
	LDA punkty1BCD
	SEC
	SBC punkty2BCD
	BPL :+
	LDA punkty1BCD+1
	SEC
	SBC punkty2BCD+1
	BPL :+
	LDA punkty1BCD+2
	SEC
	SBC punkty2BCD+2
	BPL :+
	LDA punkty1BCD+3
	SEC
	SBC punkty2BCD+3
	BPL :+
	LDA punkty1BCD+3
	CMP punkty2BCD+3
	BNE :++
	LDA #$02
	STA temp
	JMP :++
:
	DEC temp ; gracz 1 ma więcej punktów
:
	
	; napis G1
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$87
	STA PPUADDR
	
	LDA temp
	CMP #$00
	BEQ :+
	LDA #$00
	JMP :++
:
	LDA #$DE
:
	STA PPUDATA
	LDA #$F0
	STA PPUDATA
	LDA #$E1
	STA PPUDATA
	LDA numerGracza
	CMP #$01
	BEQ :+
	LDA #$DD
	JMP :++
:
	LDA #$00
:
	STA PPUDATA
	
	; napis G2
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$8C
	STA PPUADDR
	
	LDA temp
	CMP #$01
	BEQ :+
	LDA #$00
	JMP :++
:
	LDA #$DE
:
	STA PPUDATA
	LDA #$F0
	STA PPUDATA
	LDA #$E2
	STA PPUDATA
	LDA numerGracza
	CMP #$00
	BEQ :+
	LDA #$DD
	JMP :++
:
	LDA #$00
:
	STA PPUDATA
	
	; pumkty G1
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$C6
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC punkty1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; pumkty G2
	
	BIT PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$CB
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC punkty2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; linie ogółem G1
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$06
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC liczbaLinii1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; linie ogółem G2
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$0B
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC liczbaLinii2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość cheems G1
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$46
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieCheems1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość cheems G2
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$4B
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieCheems2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość doge G1
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$86
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieDoge1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość doge G2
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8B
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieDoge2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość buffdoge G1
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$C6
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieBuffDoge1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość buffdoge G2
	
	BIT PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$CB
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieBuffDoge2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość temtris G1
	
	BIT PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$06
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieTemtris1BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; ilość temtris G2
	
	BIT PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$0B
	STA PPUADDR
	
	LDA #$00
	STA PPUDATA
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC linieTemtris2BCD, X
	STA PPUDATA
	
	INX
	CPX #$04
	BEQ :+
	JMP :-
:
	
	; czas gry
	
	BIT PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$4B
	STA PPUADDR
	
	LDX #$00
	
:
	CLC
	LDA #$E0
	ADC czasGryBCD, X
	STA PPUDATA
	
	INX
	CPX #$03
	BNE :+
	
	BIT PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$4F
	STA PPUADDR
	
	JMP :-
:
	CPX #$05
	BEQ :+
	JMP :--
:
	
	RTS
	
OdtworzDzwiekRozbijanejLinii:
	
	; odtwórz dźwięk
	LDA ileNaRazLinii
	CMP #$01
	BNE :+
	
	LDA #%11001111
	STA $4004
	LDA #%11010010
	STA $4005
	LDA #%01100011
	STA $4006
	LDA #%11111000
	STA $4007
	
	JMP :++++
:
	CMP #$02
	BNE :+
	
	LDA #%00001111
	STA $4004
	LDA #%11111010
	STA $4005
	LDA #%01100011
	STA $4006
	LDA #%11111001
	STA $4007
	
	JMP :+++
:
	CMP #$03
	BNE :+
	
	LDA #%10001111
	STA $4004
	LDA #%10011010
	STA $4005
	LDA #%11010011
	STA $4006
	LDA #%11111001
	STA $4007
	
	JMP :++
:
	LDA #%01001111
	STA $4004
	LDA #%10111010
	STA $4005
	LDA #%11111111
	STA $4006
	LDA #%11111000
	STA $4007
:
	
	RTS
	
; =========================================================
; ======================== poziomy ========================
; =========================================================
	
CzyNastepnyPoziom:
	
	; jeśli liczba linii jest większa niż 30
	LDA liczbaLiniiNastepnyPoziom
	SEC
	SBC #$1E
	BPL :+
	RTS
:
	
	STA liczbaLiniiNastepnyPoziom
	DEC liczbaLiniiNastepnyPoziom
	
	INC poziom
	LDA poziom
	CMP #$10
	BNE :+
	LDA #$00
	STA poziom
:
	
	LDA #$00
	STA liczbaLiniiNastepnyPoziom
	
	LDA trybGry
	CMP #$01
	BEQ :++++
	
	; załaduj palete klocków ($3F04)
	LDA #$3F
	STA PPUADDR
	LDA #$04
	STA PPUADDR
	
	LDA #<PaletyPoziomow
	STA temp
	LDA #>PaletyPoziomow
	STA temp+1
	
	LDX #$00
:
	CPX poziom
	BEQ :+
	
	CLC
	LDA temp
	ADC #$04
	STA temp
	LDA temp+1
	ADC #$00
	STA temp+1
	
	INX
	JMP :-
:
	
	LDY #$FF
:
	INY
	LDA (temp), Y
	STA PPUDATA
	CPY #$04
	BNE :-
	
:
	
	LDA szybkoscSpadania
	CMP #$08
	BEQ :+
	
	SEC
	SBC #$04
	STA szybkoscSpadania
:
	
	RTS
	
; =========================================================
; ======================= czas gry ========================
; =========================================================
	
PoliczSekunde:
	
	INC czasGryBCD+4
	
	LDX #$04
	
:
	CPX #$03
	BNE :+
	
	LDA czasGryBCD, X
	CMP #$06
	BEQ :++
:
	LDA czasGryBCD, X
	CMP #$0A
	BNE :++
:
	LDA #$00
	STA czasGryBCD, X
	DEX
	INC czasGryBCD, X
	
	CPX #$00
	BEQ :+
	
	JMP :---
:
	
	RTS
	
; =========================================================
; =================== odtwarzanie muzyki ==================
; =========================================================
	
OdtwarzajMuzyke:
	
	LDA wlaczMuzyke
	AND #%00000100
	CMP #%00000100
	BNE :+
	
	JSR OdtwarzaczMuzykiKanalP
	
:
	LDA wlaczMuzyke
	AND #%00000010
	CMP #%00000010
	BNE :+
	
	JSR OdtwarzaczMuzykiKanalT
	
:
	LDA wlaczMuzyke
	AND #%00000001
	CMP #%00000001
	BNE :+
	
	JSR OdtwarzaczMuzykiKanalN
	
:
	
	RTS
	
OdtwarzaczMuzykiKanalP:
	
	; =============== kanał 1 - fala kwadratowa ===============
	
	LDA zegarMuzykiP
	CMP #$00
	BEQ :+
	DEC zegarMuzykiP
	RTS
:
	
	LDY #$00
	
	LDA (wskaznikDoMuzykiP), Y ; odczytujemy 5 nieużywanych i 3 wysokie bity tonu
	AND #%11111000
	CMP #%11111000
	BNE :++++
	INY
	LDA (wskaznikDoMuzykiP), Y
	CMP #$AE
	BNE :++++
	
	; kod końca bloku
	
	CLC
	LDA odtwarzanaMuzykaP
	ADC #$02
	STA odtwarzanaMuzykaP
	LDA odtwarzanaMuzykaP+1
	ADC #$00
	STA odtwarzanaMuzykaP+1
	
	LDY #$00
	
	LDA (odtwarzanaMuzykaP), Y
	AND #%11111000
	CMP #%11111000
	BNE :+++
	
	INY
	LDA (odtwarzanaMuzykaP), Y ; podwójne sprawdzenie końca bloku
	CMP #$AE
	BNE :+++
	
	; kod końca bloku, graj następną lub wyłącz muzykę
	
	LDA odtwarzajMuzykeLosowo
	CMP #$00
	BEQ :++
	
	LDA grajMuzykeMenu
	CMP #$01
	BNE :+
	JSR MuzykaGrajIntro
	RTS
:
	JSR MuzykaGrajMelodie
	
	RTS
	
:
	
	LDA #$00
	STA wlaczMuzyke
	STA $4000
	STA $4001
	STA $4002
	STA $4003
	STA $4008
	STA $4009
	STA $400A
	STA $400B
	STA $400C
	STA $400D
	STA $400E
	STA $400F
	
	RTS
	
:
	
	LDY #$00
	
	LDA (odtwarzanaMuzykaP), Y
	STA wskaznikDoMuzykiP
	INY
	LDA (odtwarzanaMuzykaP), Y
	STA wskaznikDoMuzykiP+1
	
	JMP :----
	
:
	CMP #%11101000
	BNE :+
	
	; pauza w odtwarzaniu
	
	LDA #$00
	STA $4002
	STA $4003
	
	INY
	LDA (wskaznikDoMuzykiP), Y
	STA zegarMuzykiP
	
	CLC
	LDA wskaznikDoMuzykiP
	ADC #$02
	STA wskaznikDoMuzykiP
	LDA wskaznikDoMuzykiP+1
	ADC #$00
	STA wskaznikDoMuzykiP+1
	
	JMP :++++
	
:
	CMP #%10101000
	BNE :+
	
	; wykryto bajt modyfikacji - kolejne 2 bajty zmienią ustawienia kanału
	
	INY
	LDA (wskaznikDoMuzykiP), Y
	STA $4000
	INY
	LDA (wskaznikDoMuzykiP), Y
	STA $4001
	
	CLC
	LDA wskaznikDoMuzykiP
	ADC #$03
	STA wskaznikDoMuzykiP
	LDA wskaznikDoMuzykiP+1
	ADC #$00
	STA wskaznikDoMuzykiP+1
	
	JMP :------
	
:
	CMP #%10111000
	BNE :+
	
	; przewiń o X bajtów
	
	INY
	LDA (wskaznikDoMuzykiP), Y
	
	CLC
	LDA wskaznikDoMuzykiP
	SBC temp
	STA wskaznikDoMuzykiP
	LDA wskaznikDoMuzykiP+1
	SBC #$00
	STA wskaznikDoMuzykiP+1
	
	JMP :-------
	
:
	
	LDY #$00
	
	; przesuń o licznik muzyki
	LDA (wskaznikDoMuzykiP), Y ; odczytujemy 5 nieużywanych i 3 wysokie bity tonu
	STA $4003
	INY
	LDA (wskaznikDoMuzykiP), Y ; odczytujemy 8 bitów tonu
	STA $4002
	INY
	LDA (wskaznikDoMuzykiP), Y ; odczytujemy długość w klatkach CPU
	STA zegarMuzykiP
	
	CLC
	LDA wskaznikDoMuzykiP
	ADC #$03
	STA wskaznikDoMuzykiP
	LDA wskaznikDoMuzykiP+1
	ADC #$00
	STA wskaznikDoMuzykiP+1
	
:
	
	DEC zegarMuzykiP
	
	RTS
	
OdtwarzaczMuzykiKanalT:
	
	; ================= kanał 3 fala trójkątna ================
	
	LDA zegarMuzykiT
	CMP #$00
	BEQ :+
	DEC zegarMuzykiT
	RTS
:
	
	LDY #$00
	
	LDA (wskaznikDoMuzykiT), Y ; odczytujemy 5 nieużywanych i 3 wysokie bity tonu
	AND #%11111000
	CMP #%11111000
	BNE :++
	INY
	LDA (wskaznikDoMuzykiT), Y
	CMP #$AE
	BNE :++
	
	; kod końca bloku
	
	CLC
	LDA odtwarzanaMuzykaT
	ADC #$02
	STA odtwarzanaMuzykaT
	LDA odtwarzanaMuzykaT+1
	ADC #$00
	STA odtwarzanaMuzykaT+1
	
	LDY #$00
	
	LDA (odtwarzanaMuzykaT), Y
	CMP #$FF
	BNE :+
	INY
	LDA (odtwarzanaMuzykaT), Y ; podwójne sprawdzenie końca bloku
	CMP #$AE
	BNE :++
	
	; kod końca bloku, wyłącz kanał
	
	LDA wlaczMuzyke
	AND #%11111101
	STA wlaczMuzyke
	
	LDA #$00
	STA $4008
	STA $4009
	STA $400A
	STA $400B
	
	RTS
	
:
	
	LDY #$00
	
	LDA (odtwarzanaMuzykaT), Y
	STA wskaznikDoMuzykiT
	INY
	LDA (odtwarzanaMuzykaT), Y
	STA wskaznikDoMuzykiT+1
	
	JMP :--
	
:
	CMP #%11101000
	BNE :+
	
	; pauza w odtwarzaniu
	
	LDA #$00
	STA $400A
	STA $400B
	
	INY
	LDA (wskaznikDoMuzykiT), Y
	STA zegarMuzykiT
	
	CLC
	LDA wskaznikDoMuzykiT
	ADC #$02
	STA wskaznikDoMuzykiT
	LDA wskaznikDoMuzykiT+1
	ADC #$00
	STA wskaznikDoMuzykiT+1
	
	JMP :++++
	
:
	CMP #%10101000
	BNE :+
	
	; wykryto bajt modyfikacji - kolejne 2 bajty zmienią ustawienia kanału
	
	INY
	LDA (wskaznikDoMuzykiT), Y
	STA $4008
	
	CLC
	LDA wskaznikDoMuzykiT
	ADC #$02
	STA wskaznikDoMuzykiT
	LDA wskaznikDoMuzykiT+1
	ADC #$00
	STA wskaznikDoMuzykiT+1
	
	JMP :----
	
:
	CMP #%10111000
	BNE :+
	
	; przewiń o X bajtów
	
	INY
	LDA (wskaznikDoMuzykiT), Y
	
	CLC
	LDA wskaznikDoMuzykiT
	SBC temp
	STA wskaznikDoMuzykiT
	LDA wskaznikDoMuzykiT+1
	SBC #$00
	STA wskaznikDoMuzykiT+1
	
	JMP :-----
	
:
	
	LDY #$00
	
	; przesuń o licznik muzyki
	LDA (wskaznikDoMuzykiT), Y ; odczytujemy 5 nieużywanych i 3 wysokie bity tonu
	STA $400B
	INY
	LDA (wskaznikDoMuzykiT), Y ; odczytujemy 8 bitów tonu
	STA $400A
	INY
	LDA (wskaznikDoMuzykiT), Y ; odczytujemy długość w klatkach CPU
	STA zegarMuzykiT
	
	CLC
	LDA wskaznikDoMuzykiT
	ADC #$03
	STA wskaznikDoMuzykiT
	LDA wskaznikDoMuzykiT+1
	ADC #$00
	STA wskaznikDoMuzykiT+1
	
:
	
	DEC zegarMuzykiT
	
	RTS
	
OdtwarzaczMuzykiKanalN:
	
	; ====================== kanał 4 szum =====================
	
	LDA zegarMuzykiN
	CMP #$00
	BEQ :+
	DEC zegarMuzykiN
	RTS
:
	
	LDY #$00
	
	LDA (wskaznikDoMuzykiN), Y ; odczytujemy 5 nieużywanych i 3 wysokie bity tonu
	AND #%01110000
	CMP #%01110000
	BNE :++
	INY
	LDA (wskaznikDoMuzykiN), Y
	CMP #$AE
	BNE :++
	
	; kod końca bloku
	
	CLC
	LDA odtwarzanaMuzykaN
	ADC #$02
	STA odtwarzanaMuzykaN
	LDA odtwarzanaMuzykaN+1
	ADC #$00
	STA odtwarzanaMuzykaN+1
	
	LDY #$00
	
	LDA (odtwarzanaMuzykaN), Y
	AND #%01110000
	CMP #%01110000
	BNE :+
	
	INY
	LDA (odtwarzanaMuzykaN), Y
	CMP #$AE
	BNE :+
	
	; kod końca bloku, wyłącz kanał
	
	LDA wlaczMuzyke
	AND #%11111110
	STA wlaczMuzyke
	
	LDA #$00
	STA $400C
	STA $400D
	STA $400E
	STA $400F
	
	RTS
	
:
	
	LDY #$00
	
	LDA (odtwarzanaMuzykaN), Y
	STA wskaznikDoMuzykiN
	INY
	LDA (odtwarzanaMuzykaN), Y
	STA wskaznikDoMuzykiN+1
	
	JMP :--
	
:
	CMP #%00110000
	BNE :+
	
	; pauza w odtwarzaniu
	
	LDA #$00
	STA $400E
	STA $400F
	
	INY
	LDA (wskaznikDoMuzykiN), Y
	STA zegarMuzykiN
	
	CLC
	LDA wskaznikDoMuzykiN
	ADC #$02
	STA wskaznikDoMuzykiN
	LDA wskaznikDoMuzykiN+1
	ADC #$00
	STA wskaznikDoMuzykiN+1
	
	JMP :++++
	
:
	CMP #%00010000
	BNE :+
	
	; wykryto bajt modyfikacji - kolejne 2 bajty zmienią ustawienia kanału
	
	INY
	LDA (wskaznikDoMuzykiN), Y
	STA $400C
	
	CLC
	LDA wskaznikDoMuzykiN
	ADC #$02
	STA wskaznikDoMuzykiN
	LDA wskaznikDoMuzykiN+1
	ADC #$00
	STA wskaznikDoMuzykiN+1
	
	JMP :----
	
:
	CMP #%00100000
	BNE :+
	
	; przewiń o X bajtów
	
	INY
	LDA (wskaznikDoMuzykiN), Y
	
	STA temp
	
	CLC
	LDA wskaznikDoMuzykiN
	SBC temp
	STA wskaznikDoMuzykiN
	LDA wskaznikDoMuzykiN+1
	SBC #$00
	STA wskaznikDoMuzykiN+1
	
	JMP :-----
	
:
	
	LDY #$00
	
	; przesuń o licznik muzyki
	LDA (wskaznikDoMuzykiN), Y ; odczytujemy wysokość
	STA $400E
	INY
	LDA (wskaznikDoMuzykiN), Y ; odczytujemy długość
	STA $400F
	INY
	LDA (wskaznikDoMuzykiN), Y ; odczytujemy długość dla zegara
	STA zegarMuzykiN
	
	CLC
	LDA wskaznikDoMuzykiN
	ADC #$03
	STA wskaznikDoMuzykiN
	LDA wskaznikDoMuzykiN+1
	ADC #$00
	STA wskaznikDoMuzykiN+1
	
:
	
	DEC zegarMuzykiN
	
	RTS
	
MuzykaWylaczWszystkieKanaly:
	
	LDA #%00000000
	STA wlaczMuzyke
	STA zegarMuzykiP
	STA zegarMuzykiT
	STA zegarMuzykiN
	
	STA $4000
	STA $4001
	STA $4002
	STA $4003
	STA $4008
	
	RTS
	
MuzykaGrajMelodie:
	
	; zerowanie zegarów
	
	LDA #$00
	STA zegarMuzykiP
	STA zegarMuzykiT
	STA zegarMuzykiN
	
	LDA #$07
	STA wlaczMuzyke
	
	; wylosuj melodię
	
	LDA losowa
	AND #%00000011
	CMP #$00
	BNE :+
	
	; załaduj Never Gonna Give You Up
	
	LDA #<Never_Gonna_Give_You_Up_Kanal_P
	STA odtwarzanaMuzykaP
	LDA #>Never_Gonna_Give_You_Up_Kanal_P
	STA odtwarzanaMuzykaP+1
	
	LDA #<Never_Gonna_Give_You_Up_Kanal_T
	STA odtwarzanaMuzykaT
	LDA #>Never_Gonna_Give_You_Up_Kanal_T
	STA odtwarzanaMuzykaT+1
	
	LDA #<Never_Gonna_Give_You_Up_Kanal_N
	STA odtwarzanaMuzykaN
	LDA #>Never_Gonna_Give_You_Up_Kanal_N
	STA odtwarzanaMuzykaN+1
	
	JMP :++++
:
	CMP #$01
	BNE :+
	
	; załaduj Together Forever
	
	LDA #<TogetherForeverKanalP
	STA odtwarzanaMuzykaP
	LDA #>TogetherForeverKanalP
	STA odtwarzanaMuzykaP+1
	
	LDA #<TogetherForeverKanalT
	STA odtwarzanaMuzykaT
	LDA #>TogetherForeverKanalT
	STA odtwarzanaMuzykaT+1
	
	LDA #<TogetherForeverKanalN
	STA odtwarzanaMuzykaN
	LDA #>TogetherForeverKanalN
	STA odtwarzanaMuzykaN+1
	
	JMP :+++
:
	CMP #$02
	BNE :+
	
	LDA #<Song_For_Denise_kanal_P
	STA odtwarzanaMuzykaP
	LDA #>Song_For_Denise_kanal_P
	STA odtwarzanaMuzykaP+1
	
	LDA #<Song_For_Denise_kanal_T
	STA odtwarzanaMuzykaT
	LDA #>Song_For_Denise_kanal_T
	STA odtwarzanaMuzykaT+1
	
	LDA #<Song_For_Denise_kanal_N
	STA odtwarzanaMuzykaN
	LDA #>Song_For_Denise_kanal_N
	STA odtwarzanaMuzykaN+1
	
	JMP :++
:
	
	LDA #<Szanty_Bitwa_Kanal_P
	STA odtwarzanaMuzykaP
	LDA #>Szanty_Bitwa_Kanal_P
	STA odtwarzanaMuzykaP+1
	
	LDA #<Szanty_Bitwa_Kanal_T
	STA odtwarzanaMuzykaT
	LDA #>Szanty_Bitwa_Kanal_T
	STA odtwarzanaMuzykaT+1
	
	LDA #<Szanty_Bitwa_Kanal_N
	STA odtwarzanaMuzykaN
	LDA #>Szanty_Bitwa_Kanal_N
	STA odtwarzanaMuzykaN+1
	
:
	
	LDY #$00
	LDA (odtwarzanaMuzykaP), Y
	STA wskaznikDoMuzykiP
	INY
	LDA (odtwarzanaMuzykaP), Y
	STA wskaznikDoMuzykiP+1
	
	LDY #$00
	LDA (odtwarzanaMuzykaT), Y
	STA wskaznikDoMuzykiT
	INY
	LDA (odtwarzanaMuzykaT), Y
	STA wskaznikDoMuzykiT+1
	
	LDY #$00
	LDA (odtwarzanaMuzykaN), Y
	STA wskaznikDoMuzykiN
	INY
	LDA (odtwarzanaMuzykaN), Y
	STA wskaznikDoMuzykiN+1
	
	RTS

MuzykaGrajIntro:
	
	LDA #$00
	STA zegarMuzykiP
	STA zegarMuzykiT
	STA zegarMuzykiN
	
	LDA #$07
	STA wlaczMuzyke
	
	LDA #<Korobiejniki_Kanal_P
	STA odtwarzanaMuzykaP
	LDA #>Korobiejniki_Kanal_P
	STA odtwarzanaMuzykaP+1
	
	LDY #$00
	LDA (odtwarzanaMuzykaP), Y
	STA wskaznikDoMuzykiP
	INY
	LDA (odtwarzanaMuzykaP), Y
	STA wskaznikDoMuzykiP+1
	
	LDA #<Korobiejniki_Kanal_T
	STA odtwarzanaMuzykaT
	LDA #>Korobiejniki_Kanal_T
	STA odtwarzanaMuzykaT+1
	
	LDY #$00
	LDA (odtwarzanaMuzykaT), Y
	STA wskaznikDoMuzykiT
	INY
	LDA (odtwarzanaMuzykaT), Y
	STA wskaznikDoMuzykiT+1
	
	LDA #<Korobiejniki_Kanal_N
	STA odtwarzanaMuzykaN
	LDA #>Korobiejniki_Kanal_N
	STA odtwarzanaMuzykaN+1
	
	LDY #$00
	LDA (odtwarzanaMuzykaN), Y
	STA wskaznikDoMuzykiN
	INY
	LDA (odtwarzanaMuzykaN), Y
	STA wskaznikDoMuzykiN+1
	
	RTS
	
MuzykaGrajKoniecGry:
	
	LDA #<KoniecGryKanalP
	STA odtwarzanaMuzykaP
	LDA #>KoniecGryKanalP
	STA odtwarzanaMuzykaP+1
	
	LDA #<KoniecGry_P_melodia
	STA wskaznikDoMuzykiP
	LDA #>KoniecGry_P_melodia
	STA wskaznikDoMuzykiP+1
	
	RTS

; ==================== dane zewnętrzne ====================

GitHub:
	.byte $F0, $F2, $FC, $F1, $FD, $EB, $0F, $EC, $F8, $F6, $0E, $F4, $F2, $F6, $EE, $F5, $0D, $F9, $F4
	
GitHubPalety:
	.byte $0F, $0F, $04, $05, $0F, $0F, $02, $01
	.byte $0F, $06, $15, $26, $0F, $01, $02, $0C
	.byte $0F, $07, $16, $27, $0F, $02, $0C, $11
	.byte $0F, $08, $17, $28, $0F, $01, $12, $21
	
ZerowanieAPU:
	.byte $30, $08, $00, $00
	.byte $30, $08, $00, $00
	.byte $80, $00, $00, $00
	.byte $30, $00, $00, $00
	.byte $00, $00, $00, $00

DanePalet:
	.byte $0F, $08, $17, $28 ; paleta tła 1
	.byte $0F, $12, $22, $32 ; paleta tła 2
	.byte $0F, $07, $15, $36 ; paleta tła 3
	.byte $0F, $EA, $DC, $F5 ; paleta tła 4

	.byte $0F, $08, $17, $28 ; paleta sprite'ów 1
	.byte $0F, $08, $17, $28 ; paleta sprite'ów 2
	.byte $0F, $08, $17, $28 ; paleta sprite'ów 3
	.byte $0F, $1F, $1F, $1F ; paleta sprite'ów 4

GrafikaTloMenu:
	.incbin "grafika/Menu.nam"

GrafikaTloGra:
	.incbin "grafika/Gra.nam"

GrafikaTloKoniecGryKlatka1:
	.incbin "grafika/KoniecGryKlatka1.nam"

GrafikaTloKoniecGryKlatka2:
	.incbin "grafika/KoniecGryKlatka2.nam"

DaneKlockow:
	.byte <DaneKlockowKostka, >DaneKlockowKostka
	.byte <DaneKlockowDlugi, >DaneKlockowDlugi
	.byte <DaneKlockowL, >DaneKlockowL
	.byte <DaneKlockowOdwroconeL, >DaneKlockowOdwroconeL
	.byte <DaneKlockowKrzeslo, >DaneKlockowKrzeslo
	.byte <DaneKlockowOdroconeKrzeslo, >DaneKlockowOdroconeKrzeslo
	.byte <DaneKlockowT, >DaneKlockowT

DaneKlockowKostka:
	.byte <DaneKlockowKostkaObr1, >DaneKlockowKostkaObr1
	.byte <DaneKlockowKostkaObr2, >DaneKlockowKostkaObr2
	.byte <DaneKlockowKostkaObr3, >DaneKlockowKostkaObr3
	.byte <DaneKlockowKostkaObr4, >DaneKlockowKostkaObr4

DaneKlockowDlugi:
	.byte <DaneKlockowDlugiObr1, >DaneKlockowDlugiObr1
	.byte <DaneKlockowDlugiObr2, >DaneKlockowDlugiObr2
	.byte <DaneKlockowDlugiObr3, >DaneKlockowDlugiObr3
	.byte <DaneKlockowDlugiObr4, >DaneKlockowDlugiObr4

DaneKlockowL:
	.byte <DaneKlockowLObr1, >DaneKlockowLObr1
	.byte <DaneKlockowLObr2, >DaneKlockowLObr2
	.byte <DaneKlockowLObr3, >DaneKlockowLObr3
	.byte <DaneKlockowLObr4, >DaneKlockowLObr4

DaneKlockowOdwroconeL:
	.byte <DaneKlockowOdwroconeLObr1, >DaneKlockowOdwroconeLObr1
	.byte <DaneKlockowOdwroconeLObr2, >DaneKlockowOdwroconeLObr2
	.byte <DaneKlockowOdwroconeLObr3, >DaneKlockowOdwroconeLObr3
	.byte <DaneKlockowOdwroconeLObr4, >DaneKlockowOdwroconeLObr4

DaneKlockowKrzeslo:
	.byte <DaneKlockowKrzesloObr1, >DaneKlockowKrzesloObr1
	.byte <DaneKlockowKrzesloObr2, >DaneKlockowKrzesloObr2
	.byte <DaneKlockowKrzesloObr3, >DaneKlockowKrzesloObr3
	.byte <DaneKlockowKrzesloObr4, >DaneKlockowKrzesloObr4

DaneKlockowOdroconeKrzeslo:
	.byte <DaneKlockowOdwroconeKrzesloObr1, >DaneKlockowOdwroconeKrzesloObr1
	.byte <DaneKlockowOdwroconeKrzesloObr2, >DaneKlockowOdwroconeKrzesloObr2
	.byte <DaneKlockowOdwroconeKrzesloObr3, >DaneKlockowOdwroconeKrzesloObr3
	.byte <DaneKlockowOdwroconeKrzesloObr4, >DaneKlockowOdwroconeKrzesloObr4

DaneKlockowT:
	.byte <DaneKlockowTObr1, >DaneKlockowTObr1
	.byte <DaneKlockowTObr2, >DaneKlockowTObr2
	.byte <DaneKlockowTObr3, >DaneKlockowTObr3
	.byte <DaneKlockowTObr4, >DaneKlockowTObr4

DaneKlockowKostkaObr1:
	.byte $00, $17, $18, $00
	.byte $00, $1A, $19, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowKostkaObr2:
	.byte $00, $17, $18, $00
	.byte $00, $1A, $19, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowKostkaObr3:
	.byte $00, $17, $18, $00
	.byte $00, $1A, $19, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowKostkaObr4:
	.byte $00, $17, $18, $00
	.byte $00, $1A, $19, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowDlugiObr1:
	.byte $11, $15, $15, $12
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowDlugiObr2:
	.byte $00, $13, $00, $00
	.byte $00, $16, $00, $00
	.byte $00, $16, $00, $00
	.byte $00, $14, $00, $00

DaneKlockowDlugiObr3:
	.byte $11, $15, $15, $12
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowDlugiObr4:
	.byte $00, $13, $00, $00
	.byte $00, $16, $00, $00
	.byte $00, $16, $00, $00
	.byte $00, $14, $00, $00

DaneKlockowLObr1:
	.byte $00, $17, $15, $12
	.byte $00, $14, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowLObr2:
	.byte $00, $11, $18, $00
	.byte $00, $00, $16, $00
	.byte $00, $00, $14, $00
	.byte $00, $00, $00, $00

DaneKlockowLObr3:
	.byte $00, $00, $00, $13
	.byte $00, $11, $15, $19
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowLObr4:
	.byte $00, $13, $00, $00
	.byte $00, $16, $00, $00
	.byte $00, $1A, $12, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeLObr1:
	.byte $00, $11, $15, $18
	.byte $00, $00, $00, $14
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeLObr2:
	.byte $00, $00, $13, $00
	.byte $00, $00, $16, $00
	.byte $00, $11, $19, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeLObr3:
	.byte $00, $13, $00, $00
	.byte $00, $1A, $15, $12
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeLObr4:
	.byte $00, $17, $12, $00
	.byte $00, $16, $00, $00
	.byte $00, $14, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowKrzesloObr1:
	.byte $00, $11, $18, $00
	.byte $00, $00, $1A, $12
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowKrzesloObr2:
	.byte $00, $00, $13, $00
	.byte $00, $17, $19, $00
	.byte $00, $14, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowKrzesloObr3:
	.byte $00, $11, $18, $00
	.byte $00, $00, $1A, $12
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowKrzesloObr4:
	.byte $00, $00, $13, $00
	.byte $00, $17, $19, $00
	.byte $00, $14, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeKrzesloObr1:
	.byte $00, $00, $17, $12
	.byte $00, $11, $19, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeKrzesloObr2:
	.byte $00, $13, $00, $00
	.byte $00, $1A, $18, $00
	.byte $00, $00, $14, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeKrzesloObr3:
	.byte $00, $00, $17, $12
	.byte $00, $11, $19, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowOdwroconeKrzesloObr4:
	.byte $00, $13, $00, $00
	.byte $00, $1A, $18, $00
	.byte $00, $00, $14, $00
	.byte $00, $00, $00, $00
	
DaneKlockowTObr1:
	.byte $00, $11, $1B, $12
	.byte $00, $00, $14, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowTObr2:
	.byte $00, $00, $13, $00
	.byte $00, $11, $1C, $00
	.byte $00, $00, $14, $00
	.byte $00, $00, $00, $00

DaneKlockowTObr3:
	.byte $00, $00, $13, $00
	.byte $00, $11, $1D, $12
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowTObr4:
	.byte $00, $13, $00, $00
	.byte $00, $1E, $12, $00
	.byte $00, $14, $00, $00
	.byte $00, $00, $00, $00

DaneKlockowPalety:
	.byte $0F, $01, $12, $21 ; kostka
	.byte $0F, $06, $16, $26 ; dlugi
	.byte $0F, $14, $24, $34 ; L
	.byte $0F, $17, $27, $37 ; odwroconeL
	.byte $0F, $0A, $1A, $2A ; krzeslo
	.byte $0F, $0C, $1C, $2C ; odwroconeKrzeslo
	.byte $0F, $08, $18, $27 ; T

PaletyPoziomow:
	.byte $0F, $00, $10, $20 ; 0
	.byte $0F, $06, $16, $26 ; 1
	.byte $0F, $08, $18, $27 ; 2
	.byte $0F, $01, $12, $21 ; 3
	.byte $0F, $17, $27, $37 ; 4
	.byte $0F, $14, $24, $34 ; 5
	.byte $0F, $0C, $1C, $2C ; 6
	.byte $0F, $0A, $1A, $2A ; 7
	.byte $0F, $13, $23, $33 ; 8
	.byte $0F, $16, $26, $36 ; 9
	.byte $0F, $18, $28, $38 ; 10
	.byte $0F, $19, $29, $39 ; 11
	.byte $0F, $1C, $2C, $3C ; 12
	.byte $0F, $15, $25, $35 ; 13
	.byte $0F, $1C, $2C, $3C ; 14
	.byte $0F, $1D, $2D, $3D ; 15

PozycjaLiniiWPPUL:
	.byte $CA
	.byte $EA
	.byte $0A
	.byte $2A
	.byte $4A
	.byte $6A
	.byte $8A
	.byte $AA
	.byte $CA
	.byte $EA
	.byte $0A
	.byte $2A
	.byte $4A
	.byte $6A
	.byte $8A
	.byte $AA
	.byte $CA
	.byte $EA
	.byte $0A
	.byte $2A
	.byte $4A

PozycjaLiniiWPPUH:
	.byte $20
	.byte $20
	.byte $21
	.byte $21
	.byte $21
	.byte $21
	.byte $21
	.byte $21
	.byte $21
	.byte $21
	.byte $22
	.byte $22
	.byte $22
	.byte $22
	.byte $22
	.byte $22
	.byte $22
	.byte $22
	.byte $23
	.byte $23
	.byte $23

RozbitaLiniaCheemsNapis:
	.byte $00
	.byte $EC
	.byte $F1
	.byte $EE
	.byte $EE
	.byte $F6
	.byte $FB
	.byte $00
	.byte $00
	.byte $00

RozbitaLiniaDogeNapis:
	.byte $00
	.byte $ED
	.byte $F8
	.byte $F0
	.byte $EE
	.byte $00
	.byte $00
	.byte $00
	.byte $00
	.byte $00

RozbitaLiniaBuffDogeNapis:
	.byte $00
	.byte $EB
	.byte $FD
	.byte $EF
	.byte $EF
	.byte $ED
	.byte $F8
	.byte $F0
	.byte $EE
	.byte $00

RozbitaLiniaTemtrisNapis:
	.byte $00
	.byte $FC
	.byte $EE
	.byte $F6
	.byte $FC
	.byte $FA
	.byte $F2
	.byte $FB
	.byte $00
	.byte $00

; =========================================================
; ====================== Dane Muzyki ======================
; =========================================================

; uniwersalne

Pauza640klatek:
	.byte %11101000, %11111111
	.byte %11101000, %11111111
	.byte %11101000, %10000010
	.byte %11111000, $AE

Pauza512klatek:
	.byte %11101000, %11111111
	.byte %11101000, %11111111
	.byte %11101000, %00000010
	.byte %11111000, $AE

Pauza360klatek:
	.byte %11101000, %11111111
	.byte %11101000, %01101001
	.byte %11111000, $AE

Pauza128klatek:
	.byte %11101000, %10000000
	.byte %11111000, $AE

Pauza80klatek:
	.byte %11101000, %01010000
	.byte %11111000, $AE

Pauza60klatek:
	.byte %11101000, %00111100
	.byte %11111000, $AE

Pauza45klatek:
	.byte %11101000, %00101101
	.byte %11111000, $AE

Pauza30klatek:
	.byte %11101000, %00011110
	.byte %11111000, $AE

Pauza15klatek:
	.byte %11101000, %00001111
	.byte %11111000, $AE

; =========================================================
; ====================== Korobiejniki =====================
; =========================================================

; ================== Korobiejniki kanał P =================

Korobiejniki_Kanal_P:
	.byte <Korobiejniki_P_zwrotka, >Korobiejniki_P_zwrotka
	.byte <Korobiejniki_P_zwrotka, >Korobiejniki_P_zwrotka
	.byte <Korobiejniki_P_przejscie, >Korobiejniki_P_przejscie

	.byte %11111000, $AE

Korobiejniki_P_zwrotka:
	.byte %10101000, %11111111, %00000000
	.byte %00000000, %10101000, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %10111101, %00001100
	.byte %00000000, %10101000, %00000110
	.byte %00000000, %10111101, %00000110
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %00000000, %11111101, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11111101, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %10101000, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %10111101, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %10111101, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %10101000, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11111101, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11111101, %00011000
	.byte %11101000, %00011000
	.byte %10101000, %11111111, %00000000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000110
	.byte %00000000, %10111101, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %10011111, %00001100
	.byte %00000000, %01111110, %00000110
	.byte %11101000, %00000110
	.byte %00000000, %01111110, %00000110
	.byte %00000000, %10001101, %00000110
	.byte %00000000, %10011111, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %10101000, %00000110
	.byte %11101000, %00000110
	.byte %00000000, %10101000, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %10101000, %00010010
	.byte %00000000, %10111101, %00000110
	.byte %00000000, %11010100, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11100001, %00000110
	.byte %11101000, %00000110
	.byte %00000000, %11100001, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %10111101, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %10101000, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11111101, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11111101, %00011000
	.byte %11101000, %00011000
	.byte %10101000, %11111111, %00000000

	.byte %11111000, $AE

Korobiejniki_P_przejscie:
	.byte %10101000, %11111111, %00000000
	.byte %00000000, %10101000, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %11010100, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %10111101, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %11100001, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %11010100, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %11111101, %00011000
	.byte %11101000, %00011000
	.byte %00000001, %00001100, %00110000
	.byte %11101000, %00110000
	.byte %00000000, %10101000, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %11010100, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %10111101, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %11100001, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %10101000, %00001100
	.byte %11101000, %00001100
	.byte %00000000, %01111110, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %10000101, %00011000
	.byte %11101000, %00011000
	.byte %00000000, %10101000, %00011000
	.byte %11101000, %00011000

	.byte %11111000, $AE

; ================== Korobiejniki kanał T =================

Korobiejniki_Kanal_T:
	.byte <Korobiejniki_T_inicjalizacja, >Korobiejniki_T_inicjalizacja
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_E, >Korobiejniki_T_akord_E
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_Am_przejscie, >Korobiejniki_T_akord_Am_przejscie
	.byte <Korobiejniki_T_akord_Dm, >Korobiejniki_T_akord_Dm
	.byte <Korobiejniki_T_akord_Dm, >Korobiejniki_T_akord_Dm
	.byte <Korobiejniki_T_akord_C, >Korobiejniki_T_akord_C
	.byte <Korobiejniki_T_akord_C, >Korobiejniki_T_akord_C
	.byte <Korobiejniki_T_akord_G, >Korobiejniki_T_akord_G
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	; fajnie by tu było ustawić skok o 16 w tył reagujący tylko raz
	; powtórzenie
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_E, >Korobiejniki_T_akord_E
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_Am_przejscie, >Korobiejniki_T_akord_Am_przejscie
	.byte <Korobiejniki_T_akord_Dm, >Korobiejniki_T_akord_Dm
	.byte <Korobiejniki_T_akord_Dm, >Korobiejniki_T_akord_Dm
	.byte <Korobiejniki_T_akord_C, >Korobiejniki_T_akord_C
	.byte <Korobiejniki_T_akord_C, >Korobiejniki_T_akord_C
	.byte <Korobiejniki_T_akord_G, >Korobiejniki_T_akord_G
	.byte <Korobiejniki_T_akord_Em, >Korobiejniki_T_akord_Em
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	.byte <Korobiejniki_T_akord_Am, >Korobiejniki_T_akord_Am
	; przejście
	.byte <Korobiejniki_T_przejscie_Am, >Korobiejniki_T_przejscie_Am
	.byte <Korobiejniki_T_przejscie_B, >Korobiejniki_T_przejscie_B
	.byte <Korobiejniki_T_przejscie_Am, >Korobiejniki_T_przejscie_Am
	.byte <Korobiejniki_T_przejscie_E, >Korobiejniki_T_przejscie_E
	.byte <Korobiejniki_T_przejscie_Am, >Korobiejniki_T_przejscie_Am
	.byte <Korobiejniki_T_przejscie_B, >Korobiejniki_T_przejscie_B
	.byte <Korobiejniki_T_przejscie_Am, >Korobiejniki_T_przejscie_Am
	.byte <Korobiejniki_T_przejscie_E, >Korobiejniki_T_przejscie_E

	.byte $FF, $AE

Korobiejniki_T_inicjalizacja:
	.byte %10101000, %11111111

	.byte %11111000, $AE

Korobiejniki_T_akord_Em:
	.byte %00000001, %01010010, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %00000001, %00011100, %00001100
	.byte %00000000, %11100001, %00001100

	.byte %11111000, $AE

Korobiejniki_T_akord_E:
	.byte %00000001, %01010010, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %00000001, %00001100, %00001100
	.byte %00000000, %11100001, %00001100

	.byte %11111000, $AE

Korobiejniki_T_akord_Am:
	.byte %00000000, %11111101, %00001100
	.byte %00000000, %10101000, %00001100
	.byte %00000000, %11010100, %00001100
	.byte %00000000, %10101000, %00001100

	.byte %11111000, $AE

Korobiejniki_T_akord_Am_przejscie:
	.byte %00000001, %11111011, %00000110
	.byte %11101000, %00000110
	.byte %00000001, %11000011, %00000110
	.byte %11101000, %00000110
	.byte %00000001, %10101010, %00000110
	.byte %11101000, %00000110
	.byte %00000001, %01111011, %00000110
	.byte %11101000, %00000110

	.byte %11111000, $AE

Korobiejniki_T_akord_Dm:
	.byte %00000001, %01111011, %00001100
	.byte %00000000, %11111101, %00001100
	.byte %00000001, %00111111, %00001100
	.byte %00000000, %11111101, %00001100

	.byte %11111000, $AE

Korobiejniki_T_akord_C:
	.byte %00000010, %00111001, %00001100
	.byte %00000001, %01010010, %00001100
	.byte %00000001, %10101010, %00001100
	.byte %00000001, %01010010, %00001100

	.byte %11111000, $AE

Korobiejniki_T_akord_G:
	.byte %00000001, %00011100, %00001100
	.byte %00000001, %01111011, %00001100
	.byte %00000000, %11100001, %00001100
	.byte %00000001, %01111011, %00001100
	
	.byte %11111000, $AE

Korobiejniki_T_przejscie_Am:
	.byte %00000001, %11111011, %00001100
	.byte %00000001, %01010010, %00001100
	.byte %00000001, %11111011, %00001100
	.byte %00000001, %01010010, %00001100
	.byte %00000001, %11111011, %00001100
	.byte %00000001, %01010010, %00001100
	.byte %00000001, %11111011, %00001100
	.byte %00000001, %01010010, %00001100

	.byte %11111000, $AE

Korobiejniki_T_przejscie_B:
	.byte %00000001, %11000011, %00001100
	.byte %00000001, %01111011, %00001100
	.byte %00000001, %11000011, %00001100
	.byte %00000001, %01111011, %00001100
	.byte %00000001, %11000011, %00001100
	.byte %00000001, %01111011, %00001100
	.byte %00000001, %11000011, %00001100
	.byte %00000001, %01111011, %00001100

	.byte %11111000, $AE

Korobiejniki_T_przejscie_E:
	.byte %00000010, %11001110, %00001100
	.byte %00000001, %01010010, %00001100
	.byte %00000010, %11001110, %00001100
	.byte %00000001, %01010010, %00001100
	.byte %00000010, %11001110, %00001100
	.byte %00000001, %01010010, %00001100
	.byte %00000010, %11001110, %00001100
	.byte %00000001, %01010010, %00001100

	.byte %11111000, $AE

; ================== Korobiejniki kanał N =================

Korobiejniki_Kanal_N:
	.byte <Korobiejniki_N_inicjalizacja, >Korobiejniki_N_inicjalizacja
	.byte <Korobiejniki_N_rytm, >Korobiejniki_N_rytm
	
	.byte %11111000, $AE

Korobiejniki_N_inicjalizacja:
	.byte %00010000, %01010111

	.byte %01110000, $AE

Korobiejniki_N_rytm:
	.byte %00000110, %10000000, %00001100
	.byte %00000010, %10000000, %00000110
	.byte %00000010, %10000000, %00000110
	.byte %00000010, %10000000, %00001100
	.byte %00000011, %10000000, %00001100
	.byte %00000110, %10000000, %00001100
	.byte %00000010, %10000000, %00000110
	.byte %00000010, %10000000, %00000110
	.byte %00000010, %10000000, %00001100
	.byte %00000011, %10000000, %00001100
	.byte %00100000, %00011101

	.byte %01110000, $AE

; =========================================================
; ================ Never Gonna Give You Up ================
; =========================================================

; ===================== NGGYU kanał P =====================

Never_Gonna_Give_You_Up_Kanal_P:
	.byte <NGGYU_P_Wstep_1, >NGGYU_P_Wstep_1
	.byte <NGGYU_P_Wstep_2, >NGGYU_P_Wstep_2
	.byte <NGGYU_P_Wstep_3, >NGGYU_P_Wstep_3
	.byte <NGGYU_P_Wstep_2, >NGGYU_P_Wstep_2
	.byte <NGGYU_P_Zwrotka_1, >NGGYU_P_Zwrotka_1
	.byte <NGGYU_P_I_JUST, >NGGYU_P_I_JUST
	.byte <NGGYU_P_Refren, >NGGYU_P_Refren
	.byte <Pauza60klatek, >Pauza60klatek
	.byte <NGGYU_P_Zwrotka_2, >NGGYU_P_Zwrotka_2
	.byte <NGGYU_P_I_JUST, >NGGYU_P_I_JUST
	.byte <NGGYU_P_Refren, >NGGYU_P_Refren
	.byte <Pauza30klatek, >Pauza30klatek
	.byte <NGGYU_P_Przejscie_1, >NGGYU_P_Przejscie_1
	.byte <NGGYU_P_Przejscie_1, >NGGYU_P_Przejscie_1
	.byte <NGGYU_P_Przejscie_2, >NGGYU_P_Przejscie_2
	.byte <NGGYU_P_Przejscie_2, >NGGYU_P_Przejscie_2
	.byte <Pauza30klatek, >Pauza30klatek
	.byte <NGGYU_P_Zwrotka_2, >NGGYU_P_Zwrotka_2
	.byte <NGGYU_P_I_JUST, >NGGYU_P_I_JUST
	.byte <NGGYU_P_Refren, >NGGYU_P_Refren
	.byte <Pauza30klatek, >Pauza30klatek
	.byte <NGGYU_P_Refren, >NGGYU_P_Refren
	.byte <Pauza60klatek, >Pauza60klatek
	.byte <Pauza360klatek, >Pauza360klatek

	.byte %11111000, $AE

NGGYU_P_Wstep_1:
	.byte %10101000, %11111111, %00000000
	.byte %11101000, %01001011

	.byte %11111000, $AE

NGGYU_P_Wstep_2:
	.byte %00000000, %11001000, %00101101
	.byte %00000000, %10110010, %00101101
	.byte %00000001, %00001100, %00011110
	.byte %00000000, %10110010, %00101101
	.byte %00000000, %10011111, %00101101
	.byte %11101000, %00011110
	.byte %00000000, %11001000, %00101101
	.byte %00000000, %10110010, %00101101
	.byte %00000001, %00001100, %01011010

	.byte %11111000, $AE

NGGYU_P_Wstep_3:
	.byte %11101000, %00001111
	.byte %00000000, %10000101, %00000111
	.byte %00000000, %10000101, %00001000
	.byte %00000000, %01110110, %00000111
	.byte %00000000, %01100011, %00001000
	.byte %00000000, %01110110, %00000111
	.byte %00000000, %01100011, %00001000

	.byte %11111000, $AE

NGGYU_P_Zwrotka_1:
	.byte %11101000, %01011010
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11010100, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %11101110, %00000111
	.byte %00000000, %11010100, %00001000
	.byte %00000000, %11101110, %00111100
	.byte %00000001, %00001100, %00011110
	.byte %11101000, %00101101
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %11101110, %00001111
	.byte %11101000, %00001111
	.byte %00000001, %00001100, %00001111
	.byte %00000000, %10000101, %00001111
	.byte %11101000, %00001111
	.byte %00000000, %10000101, %00001111
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %10110010, %00111100
	.byte %11101000, %00001111
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %10110010, %00001111
	.byte %11101000, %00001111
	.byte %00000000, %11101110, %00000111
	.byte %00000000, %11010100, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11010100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000001, %00001100, %00101101
	.byte %11101000, %00011110
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000001, %00001100, %00001111
	.byte %11101000, %00001111
	.byte %00000000, %10110010, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %10011111, %00001111
	.byte %00000000, %10110010, %00011110
	.byte %11101000, %00011110

	.byte %11111000, $AE

NGGYU_P_I_JUST:
	.byte %00000000, %11001000, %00111100
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %10110010, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001111
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %10011111, %00001111
	.byte %00000000, %10110010, %00011110
	.byte %00000001, %00001100, %00011110
	.byte %00000001, %00001100, %00000111
	.byte %11101000, %00110101
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %11101110, %00001111
	.byte %11101000, %00001111
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %10011111, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00010110
	.byte %11101000, %00010110

	.byte %11111000, $AE

NGGYU_P_Refren:
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %10011111, %00001111
	.byte %11101000, %00000111
	.byte %00000000, %10011111, %00010111
	.byte %00000000, %10110010, %00011110
	.byte %11101000, %00001111
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11010100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %10110010, %00001111
	.byte %11101000, %00000111
	.byte %00000000, %10110010, %00010111
	.byte %00000000, %11001000, %00011110
	.byte %11101000, %00001111
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11010100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11001000, %00011110
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %11010100, %00011110
	.byte %00000000, %11101110, %00001111
	.byte %11101000, %00001111
	.byte %00000001, %00001100, %00001111
	.byte %00000000, %10110010, %00001111
	.byte %11101000, %00001111
	.byte %00000000, %11001000, %00011110
	.byte %11101000, %00011110
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %10011111, %00001111
	.byte %11101000, %00000111
	.byte %00000000, %10011111, %00001111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00011110
	.byte %11101000, %00001111
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11010100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %10000101, %00011110
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11001000, %00101101
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11001000, %00011110
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %11010100, %00101101
	.byte %11101000, %00001111
	.byte %00000001, %00001100, %00001111
	.byte %00000000, %10110010, %00011110
	.byte %00000000, %11001000, %00011110

	.byte %11111000, $AE

NGGYU_P_Zwrotka_2:
	.byte %11101000, %00001111
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %10110010, %00010110
	.byte %11101000, %00100110
	.byte %00000000, %11010100, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000001, %00001100, %00111100
	.byte %11101000, %00011110
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000001, %00001100, %00010110
	.byte %11101000, %00010111
	.byte %00000000, %10000101, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10000101, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00010110
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %11001000, %00001111
	.byte %11101000, %00001111
	.byte %00000000, %11010100, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000111
	.byte %11101000, %00010111
	.byte %00000000, %11010100, %00001111
	.byte %00000000, %11101110, %00001111
	.byte %00000001, %00001100, %00101101
	.byte %11101000, %00101101
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001111
	.byte %00000000, %11010100, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %11101110, %00001111
	.byte %00000001, %00001100, %00010110
	.byte %11101000, %00010111
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %10011111, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00011110
	.byte %00000000, %10110010, %00010110
	.byte %11101000, %00010111

	.byte %11111000, $AE

NGGYU_P_Przejscie_1:
	.byte %00000010, %00011001, %00011110
	.byte %00000001, %00001100, %01111000
	.byte %00000000, %11001000, %00001111
	.byte %11101000, %00000111
	.byte %00000000, %11001000, %00010111
	.byte %00000000, %11010100, %00001111
	.byte %11101000, %00011110

	.byte %11111000, $AE

NGGYU_P_Przejscie_2:
	.byte %00000010, %00011001, %00011110
	.byte %00000001, %00001100, %00000111
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %10011111, %00001111
	.byte %00000001, %00001100, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11001000, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %10011111, %00001111
	.byte %11101000, %00001111
	.byte %00000000, %11001000, %00001111
	.byte %11101000, %00000111
	.byte %00000000, %11001000, %00010111
	.byte %00000000, %11010100, %00001111
	.byte %11101000, %00011110

	.byte %11111000, $AE

; ===================== NGGYU kanał T =====================

Never_Gonna_Give_You_Up_Kanal_T:
	.byte <NGGYU_T_WSTEP_1, >NGGYU_T_WSTEP_1
	.byte <NGGYU_T_REFREN_1, >NGGYU_T_REFREN_1
	.byte <NGGYU_T_REFREN_2, >NGGYU_T_REFREN_2
	.byte <NGGYU_T_REFREN_1, >NGGYU_T_REFREN_1
	.byte <NGGYU_T_WSTEP_2, >NGGYU_T_WSTEP_2
	.byte <NGGYU_T_PODKLAD_1, >NGGYU_T_PODKLAD_1
	.byte <NGGYU_T_PODKLAD_1_WAR_1, >NGGYU_T_PODKLAD_1_WAR_1
	.byte <NGGYU_T_PODKLAD_1, >NGGYU_T_PODKLAD_1
	.byte <NGGYU_T_PODKLAD_1_WAR_2, >NGGYU_T_PODKLAD_1_WAR_2
	.byte <NGGYU_T_PODKLAD_1, >NGGYU_T_PODKLAD_1
	.byte <NGGYU_T_PODKLAD_1_WAR_3, >NGGYU_T_PODKLAD_1_WAR_3
	.byte <NGGYU_T_REFREN_1, >NGGYU_T_REFREN_1
	.byte <NGGYU_T_REFREN_2, >NGGYU_T_REFREN_2
	.byte <NGGYU_T_REFREN_1, >NGGYU_T_REFREN_1
	.byte <NGGYU_T_REFREN_OUTRO, >NGGYU_T_REFREN_OUTRO
	.byte <NGGYU_T_PODKLAD_1, >NGGYU_T_PODKLAD_1
	.byte <NGGYU_T_PODKLAD_1_WAR_1, >NGGYU_T_PODKLAD_1_WAR_1
	.byte <NGGYU_T_PODKLAD_1, >NGGYU_T_PODKLAD_1
	.byte <NGGYU_T_PODKLAD_1_WAR_1, >NGGYU_T_PODKLAD_1_WAR_1
	.byte <NGGYU_T_PODKLAD_1, >NGGYU_T_PODKLAD_1
	.byte <NGGYU_T_PODKLAD_1_WAR_4, >NGGYU_T_PODKLAD_1_WAR_4
	.byte <NGGYU_T_REFREN_1_WAR_1, >NGGYU_T_REFREN_1_WAR_1
	.byte <NGGYU_T_REFREN_2_WAR_1, >NGGYU_T_REFREN_2_WAR_1
	.byte <NGGYU_T_REFREN_1_WAR_1, >NGGYU_T_REFREN_1_WAR_1
	.byte <NGGYU_T_REFREN_OUTRO_WAR_1, >NGGYU_T_REFREN_OUTRO_WAR_1
	.byte <NGGYU_T_PRZEJSCIE, >NGGYU_T_PRZEJSCIE
	.byte <NGGYU_T_PRZEJSCIE, >NGGYU_T_PRZEJSCIE
	.byte <NGGYU_T_PRZEJSCIE, >NGGYU_T_PRZEJSCIE
	.byte <NGGYU_T_PRZEJSCIE, >NGGYU_T_PRZEJSCIE
	.byte <Pauza360klatek, >Pauza360klatek
	.byte <NGGYU_T_PAUZA_WSTAWKA, >NGGYU_T_PAUZA_WSTAWKA
	.byte <Pauza360klatek, >Pauza360klatek
	.byte <NGGYU_T_PAUZA_WSTAWKA, >NGGYU_T_PAUZA_WSTAWKA
	.byte <NGGYU_T_PODKLAD_1, >NGGYU_T_PODKLAD_1
	.byte <NGGYU_T_PODKLAD_1_WAR_4, >NGGYU_T_PODKLAD_1_WAR_4
	.byte <NGGYU_T_REFREN_1_WAR_1, >NGGYU_T_REFREN_1_WAR_1
	.byte <NGGYU_T_REFREN_2_WAR_1, >NGGYU_T_REFREN_2_WAR_1
	.byte <NGGYU_T_REFREN_1_WAR_1, >NGGYU_T_REFREN_1_WAR_1
	.byte <NGGYU_T_REFREN_OUTRO_WAR_1, >NGGYU_T_REFREN_OUTRO_WAR_1
	.byte <NGGYU_T_REFREN_1_WAR_1, >NGGYU_T_REFREN_1_WAR_1
	.byte <NGGYU_T_REFREN_2_WAR_1, >NGGYU_T_REFREN_2_WAR_1
	.byte <NGGYU_T_REFREN_1_WAR_1, >NGGYU_T_REFREN_1_WAR_1
	.byte <NGGYU_T_REFREN_OUTRO_WAR_1, >NGGYU_T_REFREN_OUTRO_WAR_1
	.byte <Pauza360klatek, >Pauza360klatek

	.byte $FF, $AE

NGGYU_T_WSTEP_1:
	.byte %10101000, %11111111
	.byte %11101000, %01001011

	.byte %11111000, $AE

NGGYU_T_WSTEP_2:
	.byte %00000000, %10000101, %00111100
	.byte %00000000, %01100011, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000111
	.byte %11101000, %00001000

	.byte %11111000, $AE
	
NGGYU_T_PODKLAD_1:
	.byte %00000001, %11011110, %00000111
	.byte %11101000, %00001000
	.byte %00000001, %11011110, %00000011
	.byte %11101000, %00000100
	.byte %00000001, %11011110, %00001000
	.byte %11101000, %00000111
	.byte %00000001, %10010010, %00001000
	.byte %00000001, %10101010, %00000111
	.byte %11101000, %00001000
	.byte %00000010, %00011001, %00000111
	.byte %11101000, %00001000
	.byte %00000001, %11011110, %00000111
	.byte %11101000, %00010111
	.byte %00000010, %01111111, %00000111
	.byte %00000001, %11011110, %00000100
	.byte %11101000, %00000100
	.byte %00000001, %11011110, %00000111
	.byte %11101000, %00001000
	.byte %00000010, %00011001, %00000111
	.byte %00000001, %11011110, %00001000
	.byte %11101000, %00000111
	.byte %00000001, %10010010, %00001000
	.byte %00000001, %10101010, %00000111
	.byte %11101000, %00001000
	.byte %11101000, %00101101
	.byte %00000010, %01111111, %00000111
	.byte %00000001, %11011110, %00000100
	.byte %11101000, %00000100
	.byte %00000001, %11011110, %00000111
	.byte %11101000, %00001000
	.byte %00000010, %00011001, %00000111
	.byte %00000001, %11011110, %00001000
	.byte %11101000, %00000111
	.byte %00000001, %10010010, %00001000
	.byte %00000001, %10101010, %00000111
	.byte %11101000, %00001000
	.byte %00000010, %00011001, %00000111
	.byte %11101000, %00001000
	.byte %00000001, %11011110, %00000111
	.byte %11101000, %00010111
	.byte %00000001, %11011110, %00000100
	.byte %11101000, %00000100
	.byte %00000001, %11011110, %00000111

	.byte %11111000, $AE
	
NGGYU_T_PODKLAD_1_WAR_1:
	.byte %00000010, %11001110, %00000111
	.byte %11101000, %00001000
	.byte %00000010, %11001110, %00000100
	.byte %11101000, %00000100
	.byte %00000010, %11001110, %00000111
	.byte %11101000, %00000111
	.byte %00000010, %11001110, %00001000
	.byte %00000010, %00011001, %00000111
	.byte %11101000, %00010111
	.byte %00000010, %00011001, %00000100
	.byte %11101000, %00000100
	.byte %00000010, %00011001, %00000111
	.byte %11101000, %00001111
	.byte %00000010, %01111111, %00000111
	.byte %00000010, %00011001, %00001000

	.byte %11111000, $AE
	
NGGYU_T_PODKLAD_1_WAR_2:
	.byte %00000010, %11001110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001111
	.byte %00000000, %10110010, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %11001000, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %11101110, %00000111
	.byte %00000010, %00011001, %00001000

	.byte %11111000, $AE
	
NGGYU_T_PODKLAD_1_WAR_3:
	.byte %00000001, %11011110, %00000111
	.byte %11101000, %00001000
	.byte %00000010, %00011001, %00000111
	.byte %00000001, %11011110, %00001000
	.byte %11101000, %00000111
	.byte %00000011, %00100110, %00001000
	.byte %00000011, %01010110, %00000111
	.byte %11101000, %00010111
	.byte %00000000, %10000101, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %10000101, %00000111
	.byte %00000000, %01110110, %00000111
	.byte %00000000, %01100011, %00001000
	.byte %00000000, %01110110, %00000111
	.byte %00000000, %01100011, %00001000

	.byte %11111000, $AE

NGGYU_T_PODKLAD_1_WAR_4:
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000010, %00011001, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00000111
	.byte %00000001, %10010010, %00001000
	.byte %00000001, %00001100, %00011110
	.byte %00000000, %10000101, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %10000101, %00000111
	.byte %00000000, %01110110, %00000111
	.byte %00000000, %01100011, %00001000
	.byte %00000000, %01110110, %00000111
	.byte %00000000, %01100011, %00001000

	.byte %11111000, $AE

NGGYU_T_REFREN_1:
	.byte %00000000, %01100011, %00101101
	.byte %00000000, %01011000, %00101101
	.byte %00000000, %10000101, %00011110
	.byte %00000000, %01011000, %00101101
	.byte %00000000, %01001111, %00101101
	.byte %00000000, %01000010, %00000111
	.byte %00000000, %01001010, %00001000
	.byte %00000000, %01001111, %00000111
	.byte %00000000, %01100011, %00001000
	.byte %00000000, %01100011, %00101101
	.byte %00000000, %01011000, %00101101
	.byte %00000000, %10000101, %00011110

	.byte %11111000, $AE

NGGYU_T_REFREN_2:
	.byte %00000000, %10000101, %00111100
	.byte %11101000, %00011110
	.byte %00000000, %01000010, %00000111
	.byte %00000000, %01001010, %00001000
	.byte %00000000, %01001111, %00000111
	.byte %00000000, %01100011, %00001000

	.byte %11111000, $AE
	
NGGYU_T_REFREN_OUTRO:
	.byte %00000000, %11010100, %00011110
	.byte %00000000, %11001000, %00011110
	.byte %00000000, %01100011, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %01100011, %00000100
	.byte %11101000, %00000100
	.byte %00000011, %00100110, %00000111

	.byte %11111000, $AE

NGGYU_T_REFREN_1_WAR_1:
	.byte %00000000, %01100011, %00001111
	.byte %00000000, %11001000, %00000111
	.byte %00000000, %01100011, %00010111
	.byte %00000000, %01101001, %00001111
	.byte %00000000, %10110010, %00011110
	.byte %00000001, %00001100, %00011110
	.byte %00000000, %01100011, %00001111
	.byte %00000000, %10110010, %00000111
	.byte %00000000, %01101001, %00010111
	.byte %00000000, %01110110, %00011110
	.byte %00000000, %10011111, %00001111
	.byte %00000000, %11001000, %00011110
	.byte %00000000, %11001000, %00101101
	.byte %00000000, %10110010, %00101101
	.byte %00000001, %00001100, %00011110
	
	.byte %11111000, $AE

NGGYU_T_REFREN_2_WAR_1:
	.byte %00000000, %01101001, %00001111
	.byte %00000000, %10110010, %00001111
	.byte %00000000, %01100011, %00101101
	.byte %00000000, %01000010, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %01000010, %00000111
	.byte %00000000, %00111010, %00000111
	.byte %00000000, %00110001, %00001000
	.byte %00000000, %00111010, %00000111
	.byte %00000000, %00110001, %00001000

	.byte %11111000, $AE

NGGYU_T_REFREN_OUTRO_WAR_1:
	.byte %00000000, %01101001, %00001111
	.byte %00000000, %11001000, %00001111
	.byte %00000000, %01100011, %00011110
	.byte %00000000, %00110001, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %00110001, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %00110001, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %00110001, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %00110001, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %00110001, %00000100
	.byte %11101000, %00000100
	.byte %00000000, %00110001, %00000011
	.byte %11101000, %00000100
	.byte %00000000, %00110001, %00000100
	.byte %11101000, %00000100

	.byte %11111000, $AE

NGGYU_T_PRZEJSCIE:
	.byte %00000000, %11101110, %00001111
	.byte %11101000, %00000111
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001111
	.byte %00000000, %11101110, %00000111
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000111
	.byte %00000101, %10011101, %00001000
	.byte %00000101, %00000000, %00000100
	.byte %11101000, %00000100
	.byte %00000101, %00000000, %00000111
	.byte %00000100, %00110100, %00000111
	.byte %00000011, %10111110, %00001000
	.byte %11101000, %00000111
	.byte %00000011, %10111110, %00001000
	.byte %11101000, %00111100
	.byte %11101000, %00000111
	.byte %00000011, %10111110, %00000100
	.byte %11101000, %00000100
	.byte %00000011, %10111110, %00000100
	.byte %11101000, %00000100
	.byte %00000011, %10111110, %00000111
	.byte %00000011, %00100110, %00000111
	.byte %00000010, %11001110, %00001000
	.byte %11101000, %00000111
	.byte %00000010, %11001110, %00001000

	.byte %11111000, $AE

NGGYU_T_PAUZA_WSTAWKA:
	.byte %00000000, %10011111, %00011110
	.byte %11101000, %00001111
	.byte %00000000, %10110010, %00111100
	.byte %11101000, %00001111

	.byte %11111000, $AE

; ===================== NGGYU kanał N =====================

Never_Gonna_Give_You_Up_Kanal_N:
	.byte <NGGYU_N_Wstep, >NGGYU_N_Wstep
	.byte <NGGYU_N_Rytm, >NGGYU_N_Rytm

	.byte %11111000, $AE

NGGYU_N_Wstep:
	.byte %00010000, %01010111
	.byte %00001110, %10000000, %00000111
	.byte %00001000, %10000000, %00001000
	.byte %00110000, %00000111
	.byte %00001110, %10000000, %00001000
	.byte %00001110, %10000000, %00000111
	.byte %00001000, %10000000, %00001000
	.byte %00001000, %10000000, %00000111
	.byte %00001110, %10000000, %00001000
	.byte %00001000, %10000000, %00000111
	.byte %00001000, %10000000, %00001000

	.byte %01110000, $AE

NGGYU_N_Rytm:
	.byte %00001110, %10000000, %00001111
	.byte %00000001, %10000000, %00000111
	.byte %00000010, %10000000, %00001000
	.byte %00001000, %10000000, %00001111
	.byte %00000010, %10000000, %00001111
	.byte %00001110, %10000000, %00001111
	.byte %00000001, %10000000, %00000111
	.byte %00000010, %10000000, %00001000
	.byte %00001000, %10000000, %00001111
	.byte %00000010, %10000000, %00001111
	.byte %00100000, %00011101

	.byte %01110000, $AE

; =========================================================
; ==================== Together Forever ===================
; =========================================================

; =============== Toghether Forever kanał P ===============

TogetherForeverKanalP:
	.byte <TF_P_INICJALIZACJA, >TF_P_INICJALIZACJA
	.byte <TF_P_1, >TF_P_1
	.byte <TF_P_2, >TF_P_2
	.byte <TF_P_3, >TF_P_3
	.byte <TF_P_4, >TF_P_4
	.byte <TF_P_5, >TF_P_5
	.byte <TF_P_6, >TF_P_6
	.byte <TF_P_7, >TF_P_7
	.byte <TF_P_8, >TF_P_8
	.byte <TF_P_9, >TF_P_9
	.byte <TF_P_10, >TF_P_10
	.byte <TF_P_11, >TF_P_11
	.byte <TF_P_12, >TF_P_12
	.byte <TF_P_13, >TF_P_13
	.byte <TF_P_10, >TF_P_10
	.byte <TF_P_14, >TF_P_14
	.byte <TF_P_15, >TF_P_15
	.byte <TF_P_16, >TF_P_16
	.byte <TF_P_17, >TF_P_17
	.byte <TF_P_18, >TF_P_18
	.byte <TF_P_19, >TF_P_19
	.byte <TF_P_20, >TF_P_20
	.byte <TF_P_21, >TF_P_21
	.byte <TF_P_22, >TF_P_22
	.byte <TF_P_23, >TF_P_23
	.byte <TF_P_24, >TF_P_24
	.byte <TF_P_25, >TF_P_25
	.byte <TF_P_26, >TF_P_26
	.byte <TF_P_27, >TF_P_27
	.byte <TF_P_28, >TF_P_28
	.byte <TF_P_29, >TF_P_29
	.byte <TF_P_30, >TF_P_30
	.byte <TF_P_31, >TF_P_31
	.byte <TF_P_32, >TF_P_32
	.byte <TF_P_33, >TF_P_33
	.byte <TF_P_34, >TF_P_34
	.byte <TF_P_35, >TF_P_35
	.byte <TF_P_36, >TF_P_36
	.byte <TF_P_33, >TF_P_33
	.byte <TF_P_34, >TF_P_34
	.byte <TF_P_37, >TF_P_37
	.byte <TF_P_38, >TF_P_38
	.byte <TF_P_17, >TF_P_17
	.byte <TF_P_39, >TF_P_39
	.byte <TF_P_23, >TF_P_23
	.byte <TF_P_40, >TF_P_40
	.byte <TF_P_17, >TF_P_17
	.byte <TF_P_41, >TF_P_41
	.byte <TF_P_23, >TF_P_23
	.byte <TF_P_42, >TF_P_42
	.byte <TF_P_29, >TF_P_29
	.byte <TF_P_43, >TF_P_43
	.byte <TF_P_44, >TF_P_44
	.byte <TF_P_45, >TF_P_45
	.byte <TF_P_29, >TF_P_29
	.byte <TF_P_46, >TF_P_46
	.byte <TF_P_47, >TF_P_47
	.byte <TF_P_32, >TF_P_32
	.byte <TF_P_17, >TF_P_17
	.byte <TF_P_48, >TF_P_48
	.byte <TF_P_23, >TF_P_23
	.byte <TF_P_49, >TF_P_49
	.byte <TF_P_50, >TF_P_50
	.byte <TF_P_51, >TF_P_51
	.byte <TF_P_52, >TF_P_52
	.byte <TF_P_53, >TF_P_53
	.byte <TF_P_54, >TF_P_54
	.byte <TF_P_26, >TF_P_26
	.byte <TF_P_44, >TF_P_44
	.byte <TF_P_45, >TF_P_45
	.byte <TF_P_29, >TF_P_29
	.byte <TF_P_46, >TF_P_46
	.byte <TF_P_55, >TF_P_55
	.byte <TF_P_56, >TF_P_56
	.byte <TF_P_29, >TF_P_29
	.byte <TF_P_26, >TF_P_26
	.byte <TF_P_44, >TF_P_44
	.byte <TF_P_45, >TF_P_45
	.byte <TF_P_57, >TF_P_57
	.byte <TF_P_46, >TF_P_46
	.byte <TF_P_55, >TF_P_55
	.byte <TF_P_58, >TF_P_58
	.byte <TF_P_29, >TF_P_29
	.byte <TF_P_26, >TF_P_26
	.byte <TF_P_44, >TF_P_44
	.byte <TF_P_45, >TF_P_45
	.byte <TF_P_29, >TF_P_29
	.byte <TF_P_46, >TF_P_46
	.byte <TF_P_59, >TF_P_59
	.byte <TF_P_60, >TF_P_60
	.byte <Pauza60klatek, >Pauza60klatek
	
	.byte %11111000, $AE
	
TF_P_INICJALIZACJA:
	.byte %10101000, %11111111, %00000000
	
	.byte %11111000, $AE
	
TF_P_1:
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %11111000, $AE

TF_P_2:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %01100110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00011000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_3:
	.byte %11101000, %00010000
	.byte %00000001, %01111011, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00111000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_4:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %01100110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00010000
	.byte %11101000, %00010000
	.byte %00000000, %11111101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00011000

	.byte %11111000, $AE

TF_P_5:
	.byte %00000001, %00011100, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %00000001, %01111011, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00011000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_6:
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01011110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01101001, %00011000
	.byte %11101000, %00001000
	.byte %00000000, %01111110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00011000

	.byte %11111000, $AE

TF_P_7:
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01111110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00011000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01101001, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01011110, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_8:
	.byte %00000000, %01011000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01011110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01101001, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01111110, %00001000
	.byte %11101000, %00011000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01101001, %00001000
	.byte %11101000, %00011000

	.byte %11111000, $AE

TF_P_9:
	.byte %00000000, %01110110, %01000000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00011000

	.byte %11111000, $AE

TF_P_10:
	.byte %11101000, %00100000
	.byte %00000000, %11101110, %00010000
	.byte %11101000, %00010000
	.byte %00000000, %11101110, %00011000
	.byte %11101000, %00101000

	.byte %11111000, $AE

TF_P_11:
	.byte %00000000, %11111101, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %11101000, %00100000
	.byte %00000001, %01111011, %00010000

	.byte %11111000, $AE

TF_P_12:
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01111011, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01111011, %00010000
	.byte %00000001, %00111111, %00011000
	.byte %00000001, %01111011, %00001000
	.byte %11101000, %00100000

	.byte %11111000, $AE

TF_P_13:
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11111101, %00001000
	.byte %00000001, %00011100, %00110000
	.byte %11101000, %00111000

	.byte %11111000, $AE

TF_P_14:
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00010000
	.byte %00000001, %00111111, %00011000
	.byte %11101000, %00011000
	.byte %00000001, %01111011, %00011000

	.byte %11111000, $AE

TF_P_15:
	.byte %00000001, %00111111, %00100000
	.byte %11101000, %00001000
	.byte %00000001, %01111011, %00010000
	.byte %00000001, %00111111, %00011000
	.byte %00000001, %01111011, %00011000
	.byte %00000000, %11101110, %00010000

	.byte %11111000, $AE

TF_P_16:
	.byte %00000001, %00011100, %00110000
	.byte %11101000, %01010000

	.byte %11111000, $AE

TF_P_17:
	.byte %00000000, %11111101, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00011000
	.byte %00000001, %00011100, %00011000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_18:
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00010000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00010000
	.byte %00000001, %00001100, %00010000
	.byte %00000000, %11101110, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00100000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_19:
	.byte %00000001, %00011100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01100110, %00010000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_20:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00011000

	.byte %11111000, $AE

TF_P_21:
	.byte %00000000, %11111101, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00001100
	.byte %11101000, %00000100
	.byte %00000000, %11111101, %00011000
	.byte %00000001, %00011100, %00011000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_22:
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00100000
	.byte %11101000, %00010000

	.byte %11111000, $AE

TF_P_23:
	.byte %00000001, %00011100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00011100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01100110, %00010000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_24:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00011000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_25:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %01100110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00100000
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00100000

	.byte %11111000, $AE

TF_P_26:
	.byte %00000001, %01111011, %00010000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11101110, %00110000
	.byte %11101000, %00010000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_27:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %01100110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00100000
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00010000
	.byte %00000000, %11111101, %00001000
	.byte %00000001, %00011100, %00001000

	.byte %11111000, $AE

TF_P_28:
	.byte %00000001, %00111111, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %00000001, %01111011, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00011000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_29:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %01100110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00010000
	.byte %00000000, %11010100, %00100000
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00100000

	.byte %11111000, $AE

TF_P_30:
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_31:
	.byte %00000000, %10110010, %00010000
	.byte %00000000, %10111101, %00010000
	.byte %00000000, %11010100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00100000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00011000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_32:
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00110000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00011000

	.byte %11111000, $AE

TF_P_33:
	.byte %11101000, %00100000
	.byte %00000000, %11101110, %00010000
	.byte %11101000, %00010000
	.byte %00000000, %11101110, %00010000
	.byte %11101000, %00110000

	.byte %11111000, $AE

TF_P_34:
	.byte %00000000, %11111101, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00010000
	.byte %00000001, %00111111, %00011000
	.byte %11101000, %00011000
	.byte %00000001, %01111011, %00010000

	.byte %11111000, $AE

TF_P_35:
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01111011, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01111011, %00010000
	.byte %00000001, %00111111, %00011000
	.byte %00000001, %01111011, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00011000

	.byte %11111000, $AE

TF_P_36:
	.byte %00000000, %11111101, %00001000
	.byte %11101000, %00100000
	.byte %00000000, %11111101, %00010000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00101000

	.byte %11111000, $AE

TF_P_37:
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01111011, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01111011, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00010000
	.byte %00000000, %11111101, %00010000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_38:
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %11111101, %00001000
	.byte %00000001, %00011100, %01001000
	.byte %11101000, %00101000

	.byte %11111000, $AE

TF_P_39:
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00110000

	.byte %11111000, $AE

TF_P_40:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00010000

	.byte %11111000, $AE

TF_P_41:
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %00000000, %11101110, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00100000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_42:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_43:
	.byte %00000001, %01111011, %00010000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11101110, %00100000
	.byte %11101000, %00100000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_44:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %01100110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00010000
	.byte %00000000, %11010100, %00100000
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00010000
	.byte %00000000, %11111101, %00001000
	.byte %00000001, %00011100, %00001000

	.byte %11111000, $AE

TF_P_45:
	.byte %00000001, %00111111, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_46:
	.byte %00000001, %00011100, %00010000
	.byte %00000000, %11111101, %00010000
	.byte %00000000, %11101110, %00010000
	.byte %11101000, %00010000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %10111101, %00010000

	.byte %11111000, $AE

TF_P_47:
	.byte %00000000, %10110010, %00010000
	.byte %00000000, %10111101, %00010000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11111101, %00100000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00001100
	.byte %11101000, %00000100
	.byte %00000000, %11010100, %00001100
	.byte %11101000, %00000100

	.byte %11111000, $AE

TF_P_48:
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %00000000, %11101110, %00011000
	.byte %00000000, %11010100, %00100000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_49:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00010000

	.byte %11111000, $AE

TF_P_50:
	.byte %00000000, %01111110, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %11111101, %00010000
	.byte %11101000, %00001000
	.byte %00000000, %11111101, %00001100
	.byte %11101000, %00000100
	.byte %00000000, %11111101, %00011000
	.byte %00000001, %00011100, %00011000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_51:
	.byte %00000000, %10000101, %00001000
	.byte %11101000, %00010000
	.byte %00000001, %00001100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00010000
	.byte %00000000, %11101110, %00011000
	.byte %00000000, %11010100, %00100000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_52:
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00010000
	.byte %00000001, %00011100, %00010000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00011100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00010000
	.byte %00000001, %01100110, %00010000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_53:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_54:
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %01100110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11010100, %00100000
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00100000

	.byte %11111000, $AE

TF_P_55:
	.byte %00000000, %10110010, %00010000
	.byte %00000000, %10111101, %00010000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11111101, %00100000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00011000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_56:
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11101110, %00110000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_57:
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %01100110, %00010000
	.byte %00000000, %10111101, %00010000
	.byte %00000000, %11010100, %00100000
	.byte %00000000, %11111101, %00010000
	.byte %00000001, %00011100, %00010000
	.byte %00000001, %00111111, %00100000

	.byte %11111000, $AE

TF_P_58:
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00110000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00010000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00010000

	.byte %11111000, $AE

TF_P_59:
	.byte %00000000, %10110010, %00010000
	.byte %00000000, %10111101, %00010000
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11111101, %00001000
	.byte %11101000, %00011000
	.byte %00000000, %11101110, %00010000
	.byte %00000000, %11010100, %00011000
	.byte %11101000, %00001000

	.byte %11111000, $AE

TF_P_60:
	.byte %00000000, %11010100, %00010000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00110000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000

	.byte %11111000, $AE


; =============== Toghether Forever kanał T ===============

TogetherForeverKanalT:
	.byte <TF_T_INICJALIZACJA, >TF_T_INICJALIZACJA
	.byte <TF_T, >TF_T
	
	.byte $FF, $AE
	
TF_T_INICJALIZACJA:
	.byte %10101000, %11111111
	
	.byte %11111000, $AE
	
TF_T:

	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %01110110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %01110110, %00001000

	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000

	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000

	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000

	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000

	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000

	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000

	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000

	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00111111, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000

	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11001000, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00001100, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %00000001, %00011100, %00001000
	.byte %00000001, %00111111, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00111111, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10111101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10111101, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00001000
	.byte %11101000, %00001000
	.byte %00000001, %00111111, %00000110
	.byte %11101000, %00000010
	.byte %00000001, %00111111, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10001101, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10001101, %00001000

	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10110010, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10110010, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %10011111, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %10011111, %00001000

	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00001000
	.byte %11101000, %00001000
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00000110
	.byte %11101000, %00000010
	.byte %00000000, %11101110, %00001000


	.byte %11111000, $AE

; =============== Toghether Forever kanał N ===============

TogetherForeverKanalN:
	.byte <TF_N_INICJALIZACJA, >TF_N_INICJALIZACJA
	.byte <TF_N, >TF_N
	
	.byte %11111000, $AE
	
TF_N_INICJALIZACJA:
	.byte %00010000, %01010111
	
	.byte %01110000, $AE
	
TF_N:
	
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000100, %10000000, %00001000
	.byte %00110000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00000111, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00110000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00000011, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00000010, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000

	.byte %00001111, %10000000, %00001000
	.byte %00110000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001111, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000110, %10000000, %00001000
	.byte %00000101, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00000001, %10000000, %00001000
	.byte %00001100, %10000000, %00001000
	.byte %00001100, %10000000, %00001000

	.byte %00001111, %10000000, %01000000


	.byte %01110000, $AE

; =========================================================
; ==================== Song for Denise ====================
; =========================================================

; ================ Song for Denise kanał P ================

Song_For_Denise_kanal_P:
	.byte <SFD_P_INICJALIZACJA, >SFD_P_INICJALIZACJA
	
	; zwrotka 1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	; refren
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_3, >SFD_P_3
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_4, >SFD_P_4
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_3, >SFD_P_3
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_5, >SFD_P_5
	; zwrotka 2
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_7, >SFD_P_7
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_7, >SFD_P_7
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_7, >SFD_P_7
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_8, >SFD_P_8
	; przejście
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_3, >SFD_P_3
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_4, >SFD_P_4
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_3, >SFD_P_3
	.byte <SFD_P_2, >SFD_P_2
	.byte <SFD_P_5, >SFD_P_5
	; refren
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_7, >SFD_P_7
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_7, >SFD_P_7
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_7, >SFD_P_7
	.byte <SFD_P_6, >SFD_P_6
	.byte <SFD_P_8, >SFD_P_8
	.byte <Pauza128klatek, >Pauza128klatek
	
	.byte %11111000, $AE

SFD_P_INICJALIZACJA:
	.byte %10101000, %11111111, %00000000

	.byte %11111000, $AE

SFD_P_1:
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11101110, %00000100
    .byte %11101000, %00001100
    .byte %00000001, %00011100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11101110, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00001100

	.byte %11111000, $AE

SFD_P_2:
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000001, %00011100, %00001000
    .byte %00000000, %10111101, %00001000
    .byte %00000000, %10110010, %00001000
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11101110, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00001000
    .byte %00000000, %10111101, %00001000
    .byte %00000000, %10110010, %00001000
    .byte %00000000, %10111101, %00010000
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000001, %00011100, %00001000
    .byte %00000000, %10111101, %00001000
    .byte %00000000, %10110010, %00001000
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
	
	.byte %11111000, $AE

SFD_P_3:
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00001000
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10110010, %00001000
    .byte %11101000, %00001000
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10001101, %00001000
    .byte %11101000, %00001000

	.byte %11111000, $AE

SFD_P_4:
    .byte %00000000, %11010100, %00000100
    .byte %00000000, %11100001, %00000100
    .byte %00000000, %11101110, %00000100
    .byte %00000000, %11111101, %00000100
    .byte %00000001, %00001100, %00000100
    .byte %00000001, %00011100, %00000100
    .byte %00000001, %00101101, %00000100
    .byte %00000001, %00111111, %00000100
    .byte %00000001, %01010010, %00000100
    .byte %00000001, %01100110, %00000100
    .byte %00000001, %01111011, %00000100
    .byte %00000001, %10010010, %00000100
    .byte %00000001, %10101010, %00000100
    .byte %00000001, %11000011, %00000100
    .byte %00000001, %11011110, %00000100
    .byte %00000001, %11111011, %00000100

	.byte %11111000, $AE
	
SFD_P_5:
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10001101, %00010000
    .byte %00000000, %10110010, %00010000

	.byte %11111000, $AE
	
SFD_P_6:
	.byte %00000000, %10111101, %00010000
    .byte %00000000, %10110010, %00001000
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11101110, %00000100
    .byte %11101000, %00001100
    .byte %00000001, %00011100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00010000
    .byte %00000000, %10110010, %00010000

    .byte %00000000, %10001101, %00010000
    .byte %00000000, %10000101, %00010000
    .byte %00000000, %10011111, %00010000
    .byte %00000000, %10110010, %00001000
    .byte %00000000, %10011111, %00001000

	.byte %11111000, $AE
	
SFD_P_7:
    .byte %00000000, %10011111, %00010000
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10001101, %00010000
    .byte %00000000, %10110010, %00010000

	.byte %11111000, $AE
	
SFD_P_8:
	.byte %00000000, %10011111, %00010000
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %10111101, %00000100
    .byte %11101000, %00001100
	
	.byte %11111000, $AE

; ================ Song for Denise kanał T ================

Song_For_Denise_kanal_T:
	.byte <SFD_T_INICJALIZACJA, >SFD_T_INICJALIZACJA
	
	.byte <Pauza512klatek, >Pauza512klatek
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_2, >SFD_T_2
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <SFD_T_1, >SFD_T_1
	.byte <Pauza512klatek, >Pauza512klatek
	.byte <SFD_T_3, >SFD_T_3
	.byte <SFD_T_3, >SFD_T_3
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_T_4, >SFD_T_4
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte <SFD_P_1, >SFD_P_1
	.byte $FF, $AE

SFD_T_INICJALIZACJA:
	.byte %10101000, %11111111
	
	.byte %11111000, $AE

SFD_T_1:
    .byte %00000001, %10101010, %00010000
    .byte %11101000, %00010000
    .byte %00000001, %10101010, %00010000
    .byte %11101000, %00010000

    .byte %11101000, %01000000

    .byte %00000010, %01111111, %00010000
    .byte %11101000, %00010000
    .byte %00000010, %01111111, %00010000
    .byte %11101000, %00001000
    .byte %00000010, %01111111, %00001000

    .byte %00000010, %00111001, %00001000
    .byte %00000010, %00111001, %00001000
    .byte %11101000, %00001000
    .byte %00000010, %00111001, %00001000
    .byte %00000010, %00111001, %00001000
    .byte %00000010, %00011001, %00001000
    .byte %00000001, %11011110, %00010000

	.byte %11111000, $AE

SFD_T_2:
    .byte %00000001, %10101010, %00010000
    .byte %11101000, %00010000
    .byte %00000001, %10101010, %00010000
    .byte %11101000, %00010000

    .byte %11101000, %01000000

    .byte %00000010, %01111111, %00010000
    .byte %11101000, %00010000
    .byte %00000010, %01111111, %00010000
    .byte %11101000, %00001000
    .byte %00000010, %01111111, %00001000

    .byte %00000000, %11010100, %00000100
    .byte %00000000, %11100001, %00000100
    .byte %00000000, %11101110, %00000100
    .byte %00000000, %11111101, %00000100
    .byte %00000001, %00001100, %00000100
    .byte %00000001, %00011100, %00000100
    .byte %00000001, %00101101, %00000100
    .byte %00000001, %00111111, %00000100
    .byte %00000001, %01010010, %00000100
    .byte %00000001, %01100110, %00000100
    .byte %00000001, %01111011, %00000100
    .byte %00000001, %10010010, %00000100
    .byte %00000001, %10101010, %00000100
    .byte %00000001, %11000011, %00000100
    .byte %00000001, %11011110, %00000100
    .byte %00000001, %11111011, %00000100

	.byte %11111000, $AE

SFD_T_3:
    .byte %00000001, %10101010, %00010000
    .byte %11101000, %00010000
    .byte %00000001, %10101010, %00010000
    .byte %11101000, %00001000
    .byte %00000001, %11011110, %00001000

    .byte %00000001, %10101010, %00000100
    .byte %11101000, %00000100
    .byte %00000001, %10101010, %00001000
    .byte %11101000, %00001000
    .byte %00000001, %10101010, %00001000
    .byte %00000010, %00111001, %00010000
    .byte %00000001, %11011110, %00001000
    .byte %11101000, %00001000

    .byte %00000010, %01111111, %00010000
    .byte %11101000, %00010000
    .byte %00000010, %01111111, %00010000
    .byte %11101000, %00001000
    .byte %00000010, %01111111, %00001000

    .byte %00000010, %00111001, %00000100
    .byte %11101000, %00000100
    .byte %00000010, %00111001, %00001000
    .byte %11101000, %00001000
    .byte %00000010, %00111001, %00000100
    .byte %11101000, %00000100
    .byte %00000010, %00111001, %00000100
    .byte %11101000, %00000100
    .byte %00000010, %00011001, %00001000
    .byte %00000001, %11011110, %00010000
	
	.byte %11111000, $AE
	
SFD_T_4:
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11101110, %00000100
    .byte %11101000, %00001100
    .byte %00000001, %00011100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11101110, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00000100
    .byte %00000000, %11010100, %00000100
    .byte %11101000, %00001100

    .byte %00000000, %11010100, %00000100
    .byte %00000000, %11100001, %00000100
    .byte %00000000, %11101110, %00000100
    .byte %00000000, %11111101, %00000100
    .byte %00000001, %00001100, %00000100
    .byte %00000001, %00011100, %00000100
    .byte %00000001, %00101101, %00000100
    .byte %00000001, %00111111, %00000100
    .byte %00000001, %01010010, %00000100
    .byte %00000001, %01100110, %00000100
    .byte %00000001, %01111011, %00000100
    .byte %00000001, %10010010, %00000100
    .byte %00000001, %10101010, %00000100
    .byte %00000001, %11000011, %00000100
    .byte %00000001, %11011110, %00000100
    .byte %00000001, %11111011, %00000100
	
	.byte %11111000, $AE

; ================ Song for Denise kanał N ================

Song_For_Denise_kanal_N:
	.byte <SFD_N_INICJALIZACJA, >SFD_N_INICJALIZACJA
	
	.byte <SFD_N_1, >SFD_N_1
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_3, >SFD_N_3
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_4, >SFD_N_4
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_5, >SFD_N_5
	.byte <SFD_N_6, >SFD_N_6
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_6, >SFD_N_6
	.byte <SFD_N_6, >SFD_N_6
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	.byte <SFD_N_2, >SFD_N_2
	
	.byte %11111000, $AE

SFD_N_INICJALIZACJA:
	.byte %00010000, %01010111
	
	.byte %01110000, $AE
	
SFD_N_1:
	.byte %00110000, %11111111
	.byte %00110000, %00000001

    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000100
    .byte %00110000, %00001100
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00001100
    .byte %00000001, %10000000, %00000001
    .byte %00001010, %10000000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00001110, %10000000, %00000100

    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000100
    .byte %00110000, %00001100
    .byte %00000001, %10000000, %00000100
    .byte %00110000, %00001100
    .byte %00000001, %10000000, %00000100
    .byte %00110000, %00001100

    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00001100
    .byte %00000001, %10000000, %00000100
    .byte %00110000, %00001100
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00001100

    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00001100
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00001100

	.byte %01110000, $AE
	
SFD_N_2:
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111

	.byte %01110000, $AE

SFD_N_3:
	.byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
	
	.byte %01110000, $AE

SFD_N_4:
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111

	.byte %01110000, $AE

SFD_N_5:
	.byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
	
	.byte %01110000, $AE

SFD_N_6:
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000100
    .byte %00001010, %10000000, %00000010
    .byte %00110000, %00000010
    .byte %00001010, %10000000, %00000010
    .byte %00110000, %00000010
    .byte %00001010, %10000000, %00000010
    .byte %00110000, %00000010

    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001110, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00001010, %10000000, %00000100
    .byte %00110000, %00000100
    .byte %00000001, %10000000, %00000001
    .byte %00110000, %00000111
	
	.byte %01110000, $AE

; =========================================================
; ====================== Szanty Bitwa =====================
; =========================================================

; ================== Szanty Bitwa kanał P =================

Szanty_Bitwa_Kanal_P:
	.byte <SB_P_INICJALIZACJA, >SB_P_INICJALIZACJA
	
	; zwrotka 1
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_2, >SB_P_2
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_3, >SB_P_3
	.byte <SB_P_4, >SB_P_4
	.byte <SB_P_5, >SB_P_5
	.byte <SB_P_6, >SB_P_6
	.byte <SB_P_5, >SB_P_5
	; zwrotka 2
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_2, >SB_P_2
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_3, >SB_P_3
	.byte <SB_P_4, >SB_P_4
	.byte <SB_P_5, >SB_P_5
	.byte <SB_P_6, >SB_P_6
	.byte <SB_P_5, >SB_P_5
	; zwrotka 3
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_2, >SB_P_2
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_3, >SB_P_3
	.byte <SB_P_4, >SB_P_4
	.byte <SB_P_5, >SB_P_5
	.byte <SB_P_6, >SB_P_6
	.byte <SB_P_5, >SB_P_5
	; zwrotka 4
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_2, >SB_P_2
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_3, >SB_P_3
	.byte <SB_P_4, >SB_P_4
	.byte <SB_P_5, >SB_P_5
	.byte <SB_P_6, >SB_P_6
	.byte <SB_P_5, >SB_P_5
	; zwrotka 5
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_2, >SB_P_2
	.byte <SB_P_1, >SB_P_1
	.byte <SB_P_3, >SB_P_3
	.byte <SB_P_4, >SB_P_4
	.byte <SB_P_5, >SB_P_5
	.byte <SB_P_6, >SB_P_6
	.byte <SB_P_5, >SB_P_5
	; outro
	.byte <SB_P_7, >SB_P_7
	.byte <SB_P_7, >SB_P_7

	.byte %11111000, $AE

SB_P_INICJALIZACJA:
	.byte %10101000, %01111111, %00000000
	
	.byte %11111000, $AE

SB_P_1:
	.byte %00000000, %10101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %00000000, %10101000, %00011000
    .byte %00000000, %10111101, %00000110
    .byte %00000000, %11111101, %00010010
    .byte %00000000, %10111101, %00011000

    .byte %00000000, %11010100, %00010010
    .byte %00000000, %10111101, %00000110
    .byte %00000000, %11010100, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %00000000, %11111101, %00011000
    .byte %00000001, %00011100, %00001100
    .byte %00000000, %11111101, %00001100

    .byte %00000000, %11100001, %00001100
    .byte %00000001, %00011100, %00100100
    .byte %00000000, %11111101, %00000110
    .byte %11101000, %00000110
    .byte %00000000, %11111101, %00001100
    .byte %00000001, %00011100, %00001100
    .byte %00000001, %00101101, %00001100

	.byte %11111000, $AE

SB_P_2:
    .byte %00000001, %00011100, %00001100
    .byte %00000001, %00101101, %00001100
    .byte %00000001, %00011100, %00001100
    .byte %00000000, %11111101, %00000110
    .byte %00000000, %11100001, %00110000
    .byte %11101000, %00000110

	.byte %11111000, $AE
	
SB_P_3:
    .byte %00000001, %00011100, %00001100
    .byte %00000001, %00101101, %00001100
    .byte %00000001, %00011100, %00000110
    .byte %00000000, %11111101, %00001100
    .byte %00000000, %11100001, %00010010
    .byte %00000000, %11111101, %00001100
    .byte %00000001, %00011100, %00001100
    .byte %00000001, %00101101, %00001100

	.byte %11111000, $AE
	
SB_P_4:
    .byte %00000001, %00011100, %00011000
    .byte %00000000, %11100001, %00011000
    .byte %00000000, %11111101, %00001100
    .byte %00000001, %00011100, %00001100
    .byte %00000001, %00101101, %00001100
    .byte %00000001, %01111011, %00001100

	.byte %11111000, $AE
	
SB_P_5:
    .byte %00000001, %01010010, %00011000
    .byte %00000001, %01111011, %00011000
    .byte %00000001, %11000011, %00001100
    .byte %00000001, %01111011, %00100100

SB_P_7:
    .byte %00000001, %01010010, %00001100
    .byte %00000001, %00101101, %00000110
    .byte %00000001, %00011100, %00011000
    .byte %11101000, %00000110
    .byte %00000001, %00101101, %00001100
    .byte %00000000, %11111101, %00001100
    .byte %00000001, %00101101, %00001100
    .byte %00000001, %01111011, %00001100

    .byte %00000001, %01010010, %01001000
    .byte %11101000, %00011000

	.byte %11111000, $AE
	
SB_P_6:
    .byte %00000001, %00011100, %00001100
    .byte %00000000, %11111101, %00001100
    .byte %00000000, %11100001, %00011000
    .byte %00000000, %11111101, %00001100
    .byte %00000001, %00011100, %00001100
    .byte %00000001, %00101101, %00001100
    .byte %00000001, %01111011, %00001100

	.byte %11111000, $AE
	
; ================== Szanty Bitwa kanał T =================

Szanty_Bitwa_Kanal_T:
	.byte <SB_T_INICJALIZACJA, >SB_T_INICJALIZACJA
	
	; zwrotka 1
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_2, >SB_T_2
	.byte <SB_T_2, >SB_T_2
	; zwrotka 2
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_2, >SB_T_2
	.byte <SB_T_2, >SB_T_2
	; zwrotka 3
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_2, >SB_T_2
	.byte <SB_T_2, >SB_T_2
	; zwrotka 4
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_2, >SB_T_2
	.byte <SB_T_2, >SB_T_2
	; zwrotka 5
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_1, >SB_T_1
	.byte <SB_T_2, >SB_T_2
	.byte <SB_T_2, >SB_T_2

	.byte $FF, $AE

SB_T_INICJALIZACJA:
	.byte %10101000, %11111111
	
	.byte %11111000, $AE
	
SB_T_1:
	.byte %00000001, %01010010, %00001100
    .byte %11101000, %00001100
    .byte %00000001, %01010010, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %11101000, %00001100

    .byte %00000000, %11010100, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11111101, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11111101, %00001100
    .byte %11101000, %00001100

    .byte %00000000, %10101000, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10101000, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00001100
    .byte %11101000, %00001100

    .byte %00000001, %00011100, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11111101, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %00000000, %11111101, %00001100
    .byte %00000001, %00011100, %00001100
    .byte %00000001, %00101101, %00001100

	.byte %11111000, $AE

SB_T_2:
	.byte %00000001, %00011100, %00001100
    .byte %11101000, %00001100
    .byte %00000001, %00011100, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10111101, %00001100
    .byte %11101000, %00001100

    .byte %00000001, %01010010, %00001100
    .byte %11101000, %00001100
    .byte %00000001, %01010010, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %11101000, %00001100

    .byte %00000000, %11010100, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11010100, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %11100001, %00001100
    .byte %11101000, %00001100

    .byte %00000000, %10101000, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10101000, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10101000, %00001100
    .byte %11101000, %00001100
    .byte %00000000, %10101000, %00001100
    .byte %11101000, %00001100

	.byte %11111000, $AE

; ================== Szanty Bitwa kanał N =================

Szanty_Bitwa_Kanal_N:
	.byte <SB_N_INICJALIZACJA, >SB_N_INICJALIZACJA
	
	; zwrotka 1
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	; zwrotka 2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	; zwrotka 3
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	; zwrotka 4
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	; zwrotka 5
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2
	.byte <SB_N_1, >SB_N_1
	.byte <SB_N_2, >SB_N_2

	.byte %11111000, $AE

SB_N_INICJALIZACJA:
	.byte %00010000, %01010111
	
	.byte %01110000, $AE
	
SB_N_1:
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00000110
	.byte %00000001, %10000000, %00000110
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00001100
	
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00000110
	.byte %00000001, %10000000, %00000110
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00001100
	
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00000110
	.byte %00000001, %10000000, %00000110
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00001100

	.byte %01110000, $AE

SB_N_2:
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00001100
	.byte %00110000, %00001100
	.byte %00000001, %10000000, %00000110
	.byte %00000001, %10000000, %00000110
	.byte %00000101, %10000000, %00001100
	.byte %00000001, %10000000, %00000110
	.byte %00000101, %10000000, %00000110

	.byte %01110000, $AE

; =========================================================
; ======================= Koniec Gry ======================
; =========================================================

; =================== Koniec Gry kanał P ==================

KoniecGryKanalP:
	.byte <KoniecGry_P_melodia, >KoniecGry_P_melodia
	
	.byte %11111000, $AE

KoniecGry_P_melodia:
	.byte %10101000, %11111111, %00000000
	.byte %00000000, %10101000, %00000111
	.byte %00000000, %10001101, %00000111
	.byte %00000000, %10111101, %00000111
	.byte %00000000, %10011111, %00000111
	.byte %00000000, %11010100, %00000111
	.byte %00000000, %10101000, %00000111
	.byte %00000000, %11100001, %00000111
	.byte %00000000, %10111101, %00000111
	.byte %00000000, %11111101, %00000111
	.byte %00000000, %11010100, %00000111
	.byte %00000001, %00011100, %00000111
	.byte %00000000, %11100001, %00000111
	.byte %00000011, %11110111, %00111100

	.byte %11111000, $AE

; =========================================================
; ====================== Koniec ROMu ======================
; =========================================================

.byte "Koniec ROM"

.segment "VECTORS"
	.byte $FF, $FF
	.word START

.segment "CHARS"
	.incbin "grafika/temtris.chr"