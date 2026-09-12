const http = require("http");
const client = require("prom-client");

const PORT = Number(process.env.PORT || 3000);
const metrics = {
  requests: new client.Counter({
    name: "http_requests_total",
    help: "Total number of HTTP requests received.",
    labelNames: ["method", "route", "status_code"],
  }),
  duration: new client.Histogram({
    name: "http_request_duration_seconds",
    help: "HTTP request duration in seconds.",
    labelNames: ["method", "route", "status_code"],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
  }),
};

client.collectDefaultMetrics();

function log(level, message, fields = {}) {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    service: "jenkins-nodejs-app",
    message,
    ...fields,
  }));
}

const server = http.createServer(async (req, res) => {
  const startedAt = process.hrtime.bigint();
  const requestUrl = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  let statusCode = 200;
  let route = requestUrl.pathname;

  if (route === "/metrics") {
    res.writeHead(200, { "Content-Type": client.register.contentType });
    res.end(await client.register.metrics());
    return;
  }

  if (route === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok" }));
  } else if (route === "/") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("Hello from Jenkins CI/CD!\n");
  } else {
    statusCode = 404;
    route = "unmatched";
    res.writeHead(statusCode, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Not found" }));
  }

  const durationSeconds = Number(process.hrtime.bigint() - startedAt) / 1e9;
  metrics.requests.inc({ method: req.method, route, status_code: statusCode });
  metrics.duration.observe({ method: req.method, route, status_code: statusCode }, durationSeconds);
  if (route !== "/metrics") {
    log("info", "http_request", {
      method: req.method,
      route,
      status_code: statusCode,
      duration_ms: Number((durationSeconds * 1000).toFixed(3)),
    });
  }
});

server.listen(PORT, () => {
  log("info", "server_started", { port: PORT });
});
