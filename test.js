const { add } = require("./app");
const http = require("http");
const { createServer } = require("./server");

if (add(2, 3) !== 5) {
    throw new Error("Test failed");
}

if (add(10, 20) !== 30) {
    throw new Error("Second addition test failed");
}


test('adds two numbers correctly', () => {
    expect(add(2, 3)).toBe(5);
});

function request(server, path) {
    return new Promise((resolve, reject) => {
        const address = server.address();
        const request = http.get(`http://127.0.0.1:${address.port}${path}`, response => {
            let body = "";
            response.on("data", chunk => { body += chunk; });
            response.on("end", () => resolve({ status: response.statusCode, body }));
        });
        request.on("error", reject);
    });
}

describe("HTTP server", () => {
    let server;

    beforeAll(done => {
        server = createServer();
        server.listen(0, done);
    });

    afterAll(done => {
        server.close(done);
    });

    test("serves the application response", async () => {
        const response = await request(server, "/");
        expect(response.status).toBe(200);
        expect(response.body).toContain("Hello from Jenkins CI/CD!");
    });

    test("serves the health endpoint", async () => {
        const response = await request(server, "/health");
        expect(response.status).toBe(200);
        expect(JSON.parse(response.body)).toEqual({ status: "ok" });
    });

    test("serves Prometheus metrics", async () => {
        const response = await request(server, "/metrics");
        expect(response.status).toBe(200);
        expect(response.body).toContain("http_requests_total");
    });

    test("returns not found for unknown routes", async () => {
        const response = await request(server, "/missing");
        expect(response.status).toBe(404);
        expect(JSON.parse(response.body)).toEqual({ error: "Not found" });
    });
});
