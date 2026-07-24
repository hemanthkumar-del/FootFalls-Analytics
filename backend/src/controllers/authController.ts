import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models/User';
import { env } from '../config/env';

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { username, email, password, role } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({ success: false, message: 'Email already in use', errorCode: 'EMAIL_EXISTS' });
      return;
    }
    const password_hash = await bcrypt.hash(password, 10);
    const user = await User.create({ username, email, password_hash, role });
    res.status(201).json({ success: true, data: { id: user._id, username, email, role: user.role } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Registration failed', errorCode: 'REGISTRATION_ERROR' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      res.status(401).json({ success: false, message: 'Invalid credentials', errorCode: 'INVALID_CREDENTIALS' });
      return;
    }
    const token = jwt.sign({ id: user._id, role: user.role }, env.JWT_SECRET, { expiresIn: '1h' });
    const refreshToken = jwt.sign({ id: user._id }, env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
    res.status(200).json({ success: true, token, refreshToken, user: { id: user._id, username: user.username, role: user.role } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Login failed', errorCode: 'LOGIN_ERROR' });
  }
};
