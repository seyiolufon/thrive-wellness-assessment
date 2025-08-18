const http = require('http');
const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    return res.end('ok');
  }
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello! from Node.js! Deployed via Docker + ASG + ALB\n');
});

server.listen(PORT, () => {
  console.log(`Server listening on ${PORT}`);
});
