// Sample JavaScript file for E2E testing
const express = require('express');
const app = express();

class UserService {
    constructor() {
        this.users = new Map();
    }

    addUser(id, name) {
        this.users.set(id, { id, name, createdAt: new Date() });
    }

    getUser(id) {
        return this.users.get(id);
    }
}

app.get('/users/:id', async (req, res) => {
    const user = service.getUser(req.params.id);
    res.json(user ?? { error: 'Not found' });
});

module.exports = { UserService };
