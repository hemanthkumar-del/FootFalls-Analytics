"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getEvents = exports.getLiveStats = exports.getOverview = void 0;
const aiClient = __importStar(require("../ai/aiClient"));
const Store_1 = require("../models/Store");
const getOverview = async (req, res) => {
    try {
        const storesCount = await Store_1.Store.countDocuments();
        let aiStatus = null;
        try {
            aiStatus = await aiClient.getStatus();
        }
        catch (e) {
            console.error('AI Service unavailable');
        }
        res.status(200).json({
            success: true,
            data: {
                active_stores: storesCount,
                ai_engine_status: aiStatus ? 'Online' : 'Offline',
                total_entered: aiStatus?.total_entered || 0,
                current_occupancy: aiStatus?.current_occupancy || 0,
            }
        });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to fetch overview', errorCode: 'DASHBOARD_ERROR' });
    }
};
exports.getOverview = getOverview;
const getLiveStats = async (req, res) => {
    try {
        const aiStatus = await aiClient.getStatus();
        res.status(200).json({ success: true, data: aiStatus });
    }
    catch (error) {
        res.status(503).json({ success: false, message: 'AI Engine unavailable', errorCode: 'AI_OFFLINE' });
    }
};
exports.getLiveStats = getLiveStats;
const getEvents = async (req, res) => {
    try {
        const events = await aiClient.getEvents();
        res.status(200).json({ success: true, data: events });
    }
    catch (error) {
        res.status(503).json({ success: false, message: 'AI Engine unavailable', errorCode: 'AI_OFFLINE' });
    }
};
exports.getEvents = getEvents;
