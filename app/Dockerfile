FROM golang:1.25
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /app .
ENV PORT=80
EXPOSE 80
ENTRYPOINT ["/app"]
