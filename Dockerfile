# syntax=docker/dockerfile:1

# Pin the builder to the native build platform and cross-compile via GOARCH;
# otherwise buildx runs the toolchain under QEMU for the arm64 leg (glacial).
FROM --platform=$BUILDPLATFORM docker.io/golang:1.26 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY cmd/ cmd/
COPY api/ api/
COPY internal/ internal/
ARG TARGETARCH
RUN CGO_ENABLED=0 GOARCH=${TARGETARCH} go build -trimpath -o /out/manager ./cmd

FROM gcr.io/distroless/static:nonroot
# ghcr.io links the package to the repo through this label; the link is what
# grants the repo's Actions workflows write access to the package. Without it
# a package first created by a manual push stays user-scoped and CI cannot
# push (permission_denied: write_package).
LABEL org.opencontainers.image.source="https://github.com/lllamnyp/address-controller"
COPY --from=build /out/manager /manager
USER 65532:65532
ENTRYPOINT ["/manager"]
