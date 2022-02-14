# Temtris

Projekt gry Tetris w assemblerze cc65 dla konsoli Nintendo Entertainment System.

Kod gry został napisany całkowicie od zera, grafika jest inspirowana Tetrisem Tengen. Gościnnie wystąpili Shiba Inu Cheems oraz Owczarek Niemiecki Argo.

Sponsor projektu: <https://www.reddit.com/r/Rudzia/>

## Status projektu

Status: W trakcie prac

Szacowany postęp projektu: 96%

## Trailer

https://user-images.githubusercontent.com/57668948/146060510-e85c6ff3-d19b-48a2-86cd-e9affed738ba.mp4

[Obejrzyj trailer w serwisie YouTube](https://youtu.be/FPVM0gv1Cn8)

## W trakcie prac: Wersja 1.5

### Planowane zmiany

- [ ] naprawienie ostatniego błędu z umieszczaniem klocków
- [X] dodanie ne początek ekranu z linkiem do GitHuba i awatarem

Znane błędy

- kiedy agresywnie wciskamy wszystkie przyciski podczas umieszczania klocka czasem coś idzie nie tak z przepisywaniem danych do tła

## Wersje stabilne

## Wersja 1.4.1

Zmiany

- ostateczne naprawienie problemów z kolizjami
- dodanie pauzy w trakcie gry
- dodanie możliwości pominięcia melodii
- naprawienie błędu animacji i liczenia punktów podczas rozbijania linii między którymi jest przerwa
- obrót przy ścianie powinien powodować odsunięcie od ściany i obrót klocka
- Wyświetlenie czasu gry na ekranie końca gry

### Wersja 1.4

Zmiany

- dodanie trybu dla dwóch graczy
- dodanie muzyki Together Forever
- dodanie muzyki Szanty Bitwa
- dodanie muzyki Song For Denise
- Naprawiono bug: nie trafienie w wielokrotność 30 linii powoduje pominięcie osiągnięcia następnego poziomu ([#1](../../issues/1))
- Naprawiono bug: powrót do menu po zakończeniu gry kończy się rozpoczęciem nowej gry ([#2](../../issues/2))
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
