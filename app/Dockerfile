FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY go.mod *.go ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -o /out/app .

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/app /app
ENV PORT=80
EXPOSE 80
ENTRYPOINT ["/app"]
