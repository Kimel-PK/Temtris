# Temtris

Projekt cc65 assembly dla NES

Sponsor projektu: <https://www.reddit.com/r/Rudzia/>

## W trakcie prac: Wersja 1.4

### Planowane zmiany

- [ ] dodanie trybu dla dwóch graczy
- [ ] dodanie muzyki Together Forever
- [ ] dodanie muzyki Szanty Bitwa +
- [ ] naprawienie kolizji bardziej
- [ ] naprawienie błędu animacji podczas rozbijania linii między którymi jest przerwa

## Wersje stabilne

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

## Wersje niestabilne

Nie jestem dokładnie pewien co poszło nie tak, ale tak to świetnie wygląda, że zostawiłem te kompilacje rozwalające cały program.

Wystarczy zrobić jedną linię, a cały NES się rozpada.

- Temtris -0.1
- Temtris -0.2
