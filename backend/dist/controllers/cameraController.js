"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteCamera = exports.updateCamera = exports.getCameras = exports.createCamera = void 0;
const Camera_1 = require("../models/Camera");
const createCamera = async (req, res) => {
    try {
        const camera = await Camera_1.Camera.create(req.body);
        res.status(201).json({ success: true, data: camera });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to create camera', errorCode: 'CREATE_CAMERA_ERROR' });
    }
};
exports.createCamera = createCamera;
const getCameras = async (req, res) => {
    try {
        const cameras = await Camera_1.Camera.find().populate('assigned_store');
        res.status(200).json({ success: true, data: cameras });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to get cameras', errorCode: 'GET_CAMERAS_ERROR' });
    }
};
exports.getCameras = getCameras;
const updateCamera = async (req, res) => {
    try {
        const camera = await Camera_1.Camera.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!camera) {
            res.status(404).json({ success: false, message: 'Camera not found', errorCode: 'NOT_FOUND' });
            return;
        }
        res.status(200).json({ success: true, data: camera });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to update camera', errorCode: 'UPDATE_CAMERA_ERROR' });
    }
};
exports.updateCamera = updateCamera;
const deleteCamera = async (req, res) => {
    try {
        const camera = await Camera_1.Camera.findByIdAndDelete(req.params.id);
        if (!camera) {
            res.status(404).json({ success: false, message: 'Camera not found', errorCode: 'NOT_FOUND' });
            return;
        }
        res.status(200).json({ success: true, message: 'Camera deleted' });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to delete camera', errorCode: 'DELETE_CAMERA_ERROR' });
    }
};
exports.deleteCamera = deleteCamera;
