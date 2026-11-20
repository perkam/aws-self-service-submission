# status-api

Prosty serwis HTTP napisany w Go. Opis całego rozwiązania znajduje się w [głównym README](../README.md).

## Endpointy

| Endpoint | Odpowiedź |
| --- | --- |
| `GET /` | `{"message":"<GREETING>","version":"<SHA commita>"}` (`version` to `dev` przy lokalnym buildzie) |
| `GET /health` | `200 {"status":"ok"}` lub `503`, jeśli zmienna `GREETING` nie jest ustawiona |

## Konfiguracja

| Zmienna | Wymagana | Domyślnie | Opis |
| --- | --- | --- | --- |
| `GREETING` | Tak | Brak | Tekst zwracany przez `GET /`, różny dla każdego środowiska |
| `PORT` | Nie | `8080` | Port, na którym nasłuchuje serwis |

## Uruchomienie lokalnie

Wymagany jest Go 1.25 lub Docker. Polecenia uruchamiaj w katalogu `app`.

```sh
GREETING="Hello from local" go run .

curl http://localhost:8080/
curl http://localhost:8080/health
```

Z użyciem Dockera:

```sh
docker build -t status-api .
docker run --rm -p 8080:8080 -e GREETING="Hello from Docker" status-api
```

## Testy

```sh
go vet ./...
go test ./...
```

## Obraz

`Dockerfile` używa multi-stage build. Końcowy obraz bazuje na distroless i działa jako użytkownik non-root (`65532`).
