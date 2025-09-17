# opus_flutter_macos

Unofficial macOS implementation of the `opus_flutter` plugin. It looks for a
`libopus.dylib` in the following order:

1. The path provided via the `OPUS_FLUTTER_MACOS_LIB` environment variable.
2. A bundled dynamic library located at `packages/opus_flutter_macos/assets/libopus_universal.dylib`.
3. Common installation paths such as `/opt/homebrew/opt/opus/lib/libopus.dylib`.

Replace the placeholder asset with a real universal (`arm64` + `x86_64`) build of
libopus to ship it with your application.
