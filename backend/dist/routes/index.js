"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authRoutes_1 = __importDefault(require("./authRoutes"));
const storeRoutes_1 = __importDefault(require("./storeRoutes"));
const cameraRoutes_1 = __importDefault(require("./cameraRoutes"));
const dashboardRoutes_1 = __importDefault(require("./dashboardRoutes"));
const router = (0, express_1.Router)();
router.use('/auth', authRoutes_1.default);
router.use('/stores', storeRoutes_1.default);
router.use('/cameras', cameraRoutes_1.default);
router.use('/dashboard', dashboardRoutes_1.default);
exports.default = router;
