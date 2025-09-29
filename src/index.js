// src/index.js
const https = require('https');

exports.handler = async (event) => {
    const cpf = event.queryStringParameters?.cpf;
    if (!cpf) {
        return {
            statusCode: 400,
            body: JSON.stringify({ message: 'CPF é obrigátorio ' })
        };
    }

    const apiUrl = `https://ffc2c99a142d.ngrok-free.app/techchallenge/v1/customers?cpf=${cpf}`;

    return new Promise((resolve, reject) => {
        https.get(apiUrl, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve({
                        statusCode: 200,
                        body: data
                    });
                } else {
                    resolve({
                        statusCode: res.statusCode,
                        body: JSON.stringify({ message: 'Cliente não encontrado' })
                    });
                }
            });
        }).on('error', (err) => {
            console.error(err);
            reject({
                statusCode: 500,
                body: JSON.stringify({ message: 'Erro interno' })
            });
        });
    });
};
