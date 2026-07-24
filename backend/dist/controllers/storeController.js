"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteStore = exports.updateStore = exports.getStores = exports.createStore = void 0;
const Store_1 = require("../models/Store");
const createStore = async (req, res) => {
    try {
        const store = await Store_1.Store.create(req.body);
        res.status(201).json({ success: true, data: store });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to create store', errorCode: 'CREATE_STORE_ERROR' });
    }
};
exports.createStore = createStore;
const getStores = async (req, res) => {
    try {
        const stores = await Store_1.Store.find();
        res.status(200).json({ success: true, data: stores });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to get stores', errorCode: 'GET_STORES_ERROR' });
    }
};
exports.getStores = getStores;
const updateStore = async (req, res) => {
    try {
        const store = await Store_1.Store.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!store) {
            res.status(404).json({ success: false, message: 'Store not found', errorCode: 'NOT_FOUND' });
            return;
        }
        res.status(200).json({ success: true, data: store });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to update store', errorCode: 'UPDATE_STORE_ERROR' });
    }
};
exports.updateStore = updateStore;
const deleteStore = async (req, res) => {
    try {
        const store = await Store_1.Store.findByIdAndDelete(req.params.id);
        if (!store) {
            res.status(404).json({ success: false, message: 'Store not found', errorCode: 'NOT_FOUND' });
            return;
        }
        res.status(200).json({ success: true, message: 'Store deleted' });
    }
    catch (error) {
        res.status(500).json({ success: false, message: 'Failed to delete store', errorCode: 'DELETE_STORE_ERROR' });
    }
};
exports.deleteStore = deleteStore;
