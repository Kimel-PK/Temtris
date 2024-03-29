# Temtris

![Temtris](https://user-images.githubusercontent.com/57668948/202524793-cc0fe265-02d7-44fe-9474-41c7fee56a9a.png)

Projekt gry Tetris w assemblerze cc65 dla konsoli Nintendo Entertainment System.

> Uwaga!
> 
> Tetris jest zarejestrowanym znakiem handlowym należącym do firmy The Tetris Company, Inc.  
> Wykorzystanie w projekcie gameplayu, grafiki oraz zbliżonej nazwy służy jedynie celom edukacyjnym, z których nie czerpię żadnych korzyści materialnych!
> 
> Warning!
> 
> Tetris is a registered trademark of The Tetris Company, Inc.  
> The use of gameplay, graphics and a similar name in the project serves only educational purposes, from which I do not derive any material benefits!

Kod gry został napisany całkowicie od zera, grafika jest inspirowana Tetrisem Tengen. Gościnnie wystąpili Shiba Inu Cheems oraz Owczarek Niemiecki Argo.

Po odliczeniu najdłuższych przerw, prace nad projektem trwały około 5 miesięcy. Odliczając mniejsze przerwy, można by było powiedzieć, że całość zajęła 3 miesiące regularnej pracy.

Sponsor projektu: [r/Rudzia](https://www.reddit.com/r/Rudzia)

## Trailer

https://user-images.githubusercontent.com/57668948/146060510-e85c6ff3-d19b-48a2-86cd-e9affed738ba.mp4

Tetris theme (Korobiejniki) remix - autorstwa [DJFloop](https://www.youtube.com/channel/UCviI_n3HN0SbWlbVHHKg6Cg)

[Obejrzyj trailer w serwisie YouTube](https://youtu.be/gCDkybsxkoM)

## Uruchamianie

### ROM

Do uruchomienia ROMu potrzebny będzie dowolny emulator NES.

[Pobierz najnowszą wersję ROMu](https://github.com/Kimel-PK/Temtris/releases)

### GitHub Pages

Dzięki emulatorowi działającemu w JavaScripcie autorstwa [Bena Firshmana](https://github.com/bfirsh) gra w Temtris możliwa jest przez przeglądarkę!

[Uruchom Temtris w przeglądarce](https://kimel-pk.github.io/Temtris/)

[Repozytorium emulatora JSNES](https://github.com/bfirsh/jsnes)

## Status projektu

Status: Zakończony

Faza radości z ukończonego projektu: Trwa

Faza testowania: zakończona!

Faza projektowania: zakończona!

## Game Genie

Lista kodów zmieniających działanie gry

### Przydatne kody

- `POGEIG` - Zatrzymuje samoczynne opadanie klocków
- `IETPIT` - Następny poziom co 5 linii (czasem nawet szybciej)

### Kody rozwalające gre

- `YVIEYI` - Rozwala muzykę
- `LTGETT` - Wyłącza animację rozbijania linii
- `LVAETT` - Rozbijanie linii generuje artefakty na ekranie
- `LVYAPT` - Powolna degradacja ekranu

## Zgłoś błąd

Mimo, że projekt został ukończony, nie wykluczam, że trafią się jeszcze jakieś błędy.

Jeśli wiesz jak doprowadzić do jakiegoś błędu i chcesz pomóc naprawić Temtrisa:

1. Pobierz emulator z narzędziami developerskimi FCEUX  
    [Link do pobierania emulatora ze strony projektu](https://fceux.com/web/download.html)

2. Pobierz plik Temtris.nes  
    [Link do pobierania najnowszej wersji 1.5](https://github.com/Kimel-PK/Temtris/releases/download/1.5/Temtris.1.5.nes)

3. Uruchom FCEUX i otwórz Temtris (File -> Open...)
4. Włącz nagrywanie wejścia użytkownika (File -> Movie -> Record Movie...)
5. Wpisz dowolną nazwę pliki i wybierz `OK`
6. Zagraj i spróbuj doprowadzić do glitchy
7. Zakończ nagrywanie wejścia (File -> Movie -> Stop Movie)
8. Plik `.fm2` został zapisany w folderze instalacyjnym FCEUX i podfolderze `/movies`
9. Utwórz nowy wątek na GitHubie i załącz nagrany plik  
    [Link do tworzenia nowego wątku w repozytorium](https://github.com/Kimel-PK/Temtris/issues/new)

Dziękuję za pomoc :smile:!

## Lista zmian

### Łatka 1.5.4

Zmiany

- optymalizacja fragmentu kodu odpowiedzialnego za podmianę sprite'ów po rozbiciu linii

### Łatka 1.5.3

Zmiany

- naprawiono błąd, który powodował niepoprawne odtwarzanie drugiej ścieżki muzyki w niektórych przypadkach

### Łatka 1.5.2

Zmiany

- naprawiono błąd umożliwiający wciśnięcie klocka w inny klocek (dzięki [@michalzuch](https://github.com/michalzuch) :heart:!)

### Łatka 1.5.1

Zmiany

- naprawiono błąd czyszczenia pamięci związany z jednoczesnym rozbijaniem linii, zmianą poziomu oraz wysokim stanem zapełnienia planszy (dzięki [@KonradSiuta](https://github.com/KonradSiuta) :heart:!)

### Wersja 1.5

Zmiany

- rezygnacja z przerwań procesora na rzecz aktywnego oczekiwania na VBLANK
- dodanie ne początek ekranu z linkiem do GitHuba i awatarem
- losowy klocek na początek gry

Znane błędy

- kiedy gra toczy się przy samej górze istnieje szansa na błąd, który zeruje pamięć (wyłącza dźwięk, klocki nie losują się, błędne dane o zapełnieniu planszy)
- istnieje możliwość "wepchnięcia" jednego klocka w drugi

### Wersja 1.4.1

Zmiany

- ostateczne naprawienie problemów z kolizjami
- dodanie pauzy w trakcie gry
- dodanie możliwości pominięcia melodii
- naprawienie błędu animacji i liczenia punktów podczas rozbijania linii między którymi jest przerwa
- obrót przy ścianie powinien powodować odsunięcie od ściany i obrót klocka
- wyświetlenie czasu gry na ekranie końca gry

### Wersja 1.4

Zmiany

- dodanie trybu dla dwóch graczy
- dodanie muzyki Together Forever
- dodanie muzyki Szanty Bitwa
- dodanie muzyki Song For Denise
- Naprawiono bug: nie trafienie w wielokrotność 30 linii powoduje pominięcie osiągnięcia następnego poziomu ([#1](../../issues/1)) (dzięki [@SzymenL0K0](https://github.com/SzymenL0K0) :heart:!)
- Naprawiono bug: powrót do menu po zakończeniu gry kończy się rozpoczęciem nowej gry ([#2](../../issues/2)) (dzięki [@SzymenL0K0](https://github.com/SzymenL0K0) :heart:!)
- Naprawiono bug: jeśli klocek zostanie przesunięty w lewo lub w prawo, a następną klatką będzie jego obrót to kolizja zostanie zignorowana

Znane problemy

- Podczas zmiany poziomu z niewyjaśnionych przyczyn czasem zostają wyzerowane zmienne od $50 do $FF
- Jeśli zbuduje się wysoką wieże i zrobi linię to powstaje dziura w ramce planszy (błąd samoczynnie znikął?)

### Wersja 1.3.1

Zmiany

- dodanie muzyki Korobieniki w menu

### Wersja 1.3

Zmiany

- odświeżenie wyglądu logo
- naprawienie kolizji
- ulepszenie sterowania
- losowy odtwarzacz muzyki

> W menu muzyka została zmieniona na pusty placeholder ale odtwarzacz wciąż próbuje ją normalnie interpretować, zbyt długie siedzenie w menu może skończyć się dziwnymi dźwiękami
>
> Odtwarzacz muzyki wybiera losowo z pośród jednej melodii, jest zaimplementowany, ale nie działa jeszcze w pełni

### Wersja 1.2

Zmiany:

- zmiany w grafice Cheemsa
- optymalizacja muzyki żeby nie zajmowała 1KB pamieci
- ulepszenia techniczne odtwarzacza muzyki

> Niektóre emulatory mogą inaczej odwzorowywać kolory niż fceux64, którym debuguje, na przykład na Nestopii Cheems jest zielonkawy chyba że zaznaczymy w opcjach wideo "boost yellow"

### Wersja 1.1

Zmiany

- zmiany grafiki
- naprawiono miganie ekranu przy stawianiu klocka
- dodano animacje rozbijania linii

### Wersja 1.0

Działa jako tako, ale stabilnie

Znane błędy

- da się bez problemu "wbić" klocek w inny klocek jak obracamy go i ruszamy jednocześnie
- rick roll powoduje problemy z rozwalaniem się linii dlatego musiałem zrobić żeby lekko rwał przy stawianiu klocka
- jeśli z powodu nieznanego błędu linia rozbije się niepoprawnie to nie ma sensu grać dalej, problemy się tylko będą pogłębiać

Rzeczy do zrobienia

- animacja rozbijania się linii z napisami co to za linia (pojedyncza - cheems, 2x - doge, 3x - buffdoge, 4x - temtris)
- poukładanie lepiej kodu żeby rick roll nie rwał i żeby ekran dziwnie nie migał na czarno po postawieniu klocka
- więcej muzyki odtwarzanej losowo!
- naprawić paletę barw cheemsa
- jak jakiś grafik się znajdzie to można poprawić wygląd cheemsa albo bloków

## Ekskluzywne materiały dodatkowe

### Muzyka

Pliki midi, które przepisywałem do Excela lub częściowo konwertowałem zewnętrznym programem w C# (który szybko się sypnął) na format obsługiwany przez Temtris.

### Wersje niestabilne

Nie jestem dokładnie pewien co poszło nie tak, ale tak to świetnie wygląda, że zostawiłem te kompilacje rozwalające cały program.

Wystarczy zrobić jedną linię, a cały NES się rozpada.

- Temtris -0.1
- Temtris -0.2

### Pozostałe pliki

- Konwerter muzyki w Excelu
- Szkice i concept arty przepisywane do plików `.chr` przy użyciu programu `yychr`
- Ściąga z adresami i opisami rejestrów
- skrypt `Temtris debug.lua` do emulatora FCEUX
