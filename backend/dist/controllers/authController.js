"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.login = exports.register = void 0;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const User_1 = require("../models/User");
const env_1 = require("../config/env");
const register = async (req, res) => {
    try {
        const { username, email, password, role } = req.body;
        const existingUser = await User_1.User.findOne({ email });
        if (existingUser) {
            res.status(400).json({ success: false, message: 'Email already in use', errorCode: 'EMAIL_EXISTS' });
            return;
        }
        const password_hash = await bcryptjs_1.default.hash(password, 10);
        const user = await User_1.User.create({ username, email, password_hash, role });
        res.status(201).json({ success: true, data: { id: user._id, username, email, role: user.role } });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Registration failed', errorCode: 'REGISTRATION_ERROR' });
    }
};
exports.register = register;
const login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User_1.User.findOne({ email });
        if (!user || !(await bcryptjs_1.default.compare(password, user.password_hash))) {
            res.status(401).json({ success: false, message: 'Invalid credentials', errorCode: 'INVALID_CREDENTIALS' });
            return;
        }
        const token = jsonwebtoken_1.default.sign({ id: user._id, role: user.role }, env_1.env.JWT_SECRET, { expiresIn: '1h' });
        const refreshToken = jsonwebtoken_1.default.sign({ id: user._id }, env_1.env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
        res.status(200).json({ success: true, token, refreshToken, user: { id: user._id, username: user.username, role: user.role } });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Login failed', errorCode: 'LOGIN_ERROR' });
    }
};
exports.login = login;
