import axios from 'axios';
import { env } from '../config/env';

const aiApi = axios.create({
  baseURL: `${env.FASTAPI_URL}/api/v1`,
  timeout: 5000, // 5 seconds timeout
});

export const getHealth = async () => (await aiApi.get('/health')).data;
export const getStatus = async () => (await aiApi.get('/status')).data;
export const getStatistics = async () => (await aiApi.get('/statistics')).data;
export const getEvents = async () => (await aiApi.get('/events')).data;
export const getCameraInfo = async () => (await aiApi.get('/camera')).data;
export const getConfig = async () => (await aiApi.get('/config')).data;
export const resetCounters = async () => (await aiApi.post('/reset')).data;
