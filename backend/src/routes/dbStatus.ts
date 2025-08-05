import express from 'express';
const path = require('path');
const databaseConfig = require(path.join(__dirname, '../config/databaseAdapter')).default;

const router = express.Router();



export default router;
