# HTTPResponseDecoder

`HTTPResponseDecoder` defines the contract we expect from the backend transport layer. Its responsibility is to turn “bytes + HTTP metadata” into a typed payload (or an actionable failure) so that the rest of the module never has to reason about status codes, headers, or `JSONSerialization`.

## Design Notes

- **Consistent status semantics:** 304 responses become `.notModified`, success payloads always carry their ETag, and 4xx/5xx ranges map to module-level errors instead of leaking raw status codes.
- **Predictable failure surface:** Every transport or decoding issue collapses into a small set of error cases (`unauthorized`, `invalidData`, etc.), so higher layers never need to inspect `HTTPURLResponse` directly.
- **Single choke point:** All networking clients should funnel responses through this helper to keep cache validation, logging, and telemetry consistent.
- **Configurable JSON semantics:** Inject a custom `JSONDecoder` when you need bespoke date/key strategies without rewriting the HTTP handling.

## Collaboration With Prompt Parsing

1. Fetch `(Data, HTTPURLResponse)` from the backend.
2. Ask the decoder to interpret it as `DecodedResponse<[String]>`.
3. If the decoder reports `.response`, forward the `[String]` to `PromptsHTTPResponseProcessor`.

This handoff boundary is the only coupling between transport and parsing layers, which keeps both pieces independently testable and future-proof (e.g., replacing the transport with gRPC would only require swapping this component).
