const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 5000;

app.use(express.static('public'));
app.use(express.json());

app.get('/contract', (req, res) => {
    const contractPath = path.join(__dirname, 'contracts', 'ViethereumToken.sol');
    const contract = fs.readFileSync(contractPath, 'utf8');
    
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Viethereum Contract Code</title>
            <style>
                body {
                    font-family: 'Courier New', monospace;
                    background: #1e1e1e;
                    color: #d4d4d4;
                    padding: 20px;
                    margin: 0;
                }
                pre {
                    background: #2d2d2d;
                    padding: 20px;
                    border-radius: 8px;
                    overflow-x: auto;
                    line-height: 1.5;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 20px;
                    border-radius: 8px;
                    margin-bottom: 20px;
                }
                .back-btn {
                    background: #667eea;
                    color: white;
                    padding: 10px 20px;
                    text-decoration: none;
                    border-radius: 5px;
                    display: inline-block;
                    margin-bottom: 20px;
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Viethereum Token Contract</h1>
                <p>Symbol: VIΞTH</p>
            </div>
            <a href="/" class="back-btn">← Back to Home</a>
            <pre><code>${contract.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</code></pre>
        </body>
        </html>
    `);
});

app.get('/deploy', (req, res) => {
    const deployScript = fs.readFileSync(path.join(__dirname, 'contracts', 'deploy.js'), 'utf8');
    
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Deploy Viethereum Token</title>
            <style>
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    padding: 20px;
                    margin: 0;
                }
                .container {
                    max-width: 900px;
                    margin: 0 auto;
                    background: white;
                    padding: 40px;
                    border-radius: 12px;
                }
                h1 {
                    color: #667eea;
                }
                h2 {
                    color: #764ba2;
                    margin-top: 30px;
                }
                code {
                    background: #f0f0f0;
                    padding: 2px 6px;
                    border-radius: 3px;
                    font-family: 'Courier New', monospace;
                }
                pre {
                    background: #2d2d2d;
                    color: #d4d4d4;
                    padding: 15px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                .step {
                    background: #f7f7f7;
                    padding: 20px;
                    margin: 15px 0;
                    border-radius: 8px;
                    border-left: 4px solid #667eea;
                }
                .back-btn {
                    background: #667eea;
                    color: white;
                    padding: 10px 20px;
                    text-decoration: none;
                    border-radius: 5px;
                    display: inline-block;
                    margin-bottom: 20px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <a href="/" class="back-btn">← Back to Home</a>
                <h1>Deployment Instructions</h1>
                
                <h2>Prerequisites</h2>
                <div class="step">
                    <p>Make sure you have:</p>
                    <ul>
                        <li>Node.js installed</li>
                        <li>Hardhat installed (<code>npm install</code>)</li>
                        <li>An Ethereum wallet with some ETH for gas fees</li>
                    </ul>
                </div>

                <h2>Step 1: Compile the Contract</h2>
                <div class="step">
                    <pre>npx hardhat compile</pre>
                </div>

                <h2>Step 2: Start Local Hardhat Network</h2>
                <div class="step">
                    <pre>npx hardhat node</pre>
                </div>

                <h2>Step 3: Deploy to Local Network</h2>
                <div class="step">
                    <pre>npx hardhat run contracts/deploy.js --network localhost</pre>
                </div>

                <h2>Step 4: Deploy to Testnet (e.g., Sepolia)</h2>
                <div class="step">
                    <p>First, configure your <code>hardhat.config.js</code> with your network and private key, then:</p>
                    <pre>npx hardhat run contracts/deploy.js --network sepolia</pre>
                </div>

                <h2>Deployment Script</h2>
                <pre><code>${deployScript.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</code></pre>
            </div>
        </body>
        </html>
    `);
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Viethereum Token Info Server running on port ${PORT}`);
    console.log(`Open your browser to view the token information`);
});
