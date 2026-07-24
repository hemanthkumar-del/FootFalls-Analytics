"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.resetCounters = exports.getConfig = exports.getCameraInfo = exports.getEvents = exports.getStatistics = exports.getStatus = exports.getHealth = void 0;
const axios_1 = __importDefault(require("axios"));
const env_1 = require("../config/env");
const aiApi = axios_1.default.create({
    baseURL: `${env_1.env.FASTAPI_URL}/api/v1`,
    timeout: 5000, // 5 seconds timeout
});
const getHealth = async () => (await aiApi.get('/health')).data;
exports.getHealth = getHealth;
const getStatus = async () => (await aiApi.get('/status')).data;
exports.getStatus = getStatus;
const getStatistics = async () => (await aiApi.get('/statistics')).data;
exports.getStatistics = getStatistics;
const getEvents = async () => (await aiApi.get('/events')).data;
exports.getEvents = getEvents;
const getCameraInfo = async () => (await aiApi.get('/camera')).data;
exports.getCameraInfo = getCameraInfo;
const getConfig = async () => (await aiApi.get('/config')).data;
exports.getConfig = getConfig;
const resetCounters = async () => (await aiApi.post('/reset')).data;
exports.resetCounters = resetCounters;
