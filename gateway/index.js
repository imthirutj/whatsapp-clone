const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 4000; // Default to 4000 for gateway

// Nodes to check - Replace with your actual deployment URLs
const NODES = [
    'http://localhost:3000', // Primary backend
    // 'https://your-backup-node.onrender.com'
];

let activeNode = NODES[0];

// Health check function to find an active node
async function updateActiveNode() {
    console.log('--- Checking for active node ---');
    for (const node of NODES) {
        try {
            // Check if the node is alive
            const response = await axios.get(`${node}/api/health`, { 
                timeout: 5000,
                validateStatus: (status) => true
            });
            
            if (response.status >= 500) {
                console.log(`Node ${node} is returning ERROR (Status: ${response.status}).`);
                continue;
            }

            console.log(`Node ${node} is ACTIVE (Status: ${response.status}).`);
            activeNode = node;
            return;
        } catch (error) {
            console.log(`Node ${node} is DOWN or unreachable. Error: ${error.message}`);
        }
    }
    console.log('No active nodes found! Defaulting to first node.');
    activeNode = NODES[0];
}

// Update the active node on startup and every 5 minutes
updateActiveNode();
setInterval(updateActiveNode, 5 * 60 * 1000);

// Proxy middleware
const proxy = createProxyMiddleware({
    target: activeNode, 
    router: () => activeNode,
    changeOrigin: true,
    ws: true,
    logLevel: 'debug',
    onError: (err, req, res) => {
        console.error('Proxy Error:', err.message);
        updateActiveNode();
        res.status(503).send('Service temporarily unavailable. Retrying node selection...');
    }
});

// Status page and Health check for the gateway itself
app.get('/gateway/status', (req, res) => {
    res.json({
        activeNode,
        allNodes: NODES,
        status: 'online'
    });
});

// Log proxying
app.use((req, res, next) => {
    if (req.url === '/gateway/status') return next();
    console.log(`[Proxying] ${req.method} ${req.url} -> ${activeNode}`);
    next();
});

app.use('/', proxy);

const server = app.listen(PORT, () => {
    console.log(`Gateway running on port ${PORT}`);
    console.log(`Initial target: ${activeNode}`);
});

// Handle WebSocket upgrades
server.on('upgrade', proxy.upgrade);
