"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const swagger_ui_express_1 = __importDefault(require("swagger-ui-express"));
const env_1 = require("./config/env");
const database_1 = require("./config/database");
const errorHandler_1 = require("./middleware/errorHandler");
const routes_1 = __importDefault(require("./routes"));
const app = (0, express_1.default)();
// Connect to MongoDB
(0, database_1.connectDatabase)();
// Middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use((0, morgan_1.default)('dev'));
// Rate Limiting
const limiter = (0, express_rate_limit_1.default)({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
});
app.use('/api', limiter);
// Swagger documentation setup
const swaggerDocument = {
    openapi: '3.0.0',
    info: {
        title: 'FootFalls API',
        version: '1.0.0',
        description: 'API documentation for FootFalls backend',
    },
    servers: [{ url: `http://localhost:${env_1.env.PORT}/api` }],
    paths: {},
};
app.use('/api-docs', swagger_ui_express_1.default.serve, swagger_ui_express_1.default.setup(swaggerDocument));
// Routes
app.use('/api', routes_1.default);
// Error Handling
app.use(errorHandler_1.errorHandler);
app.listen(env_1.env.PORT, () => {
    console.log(`Server running on port ${env_1.env.PORT}`);
    console.log(`Swagger docs available at http://localhost:${env_1.env.PORT}/api-docs`);
});
exports.default = app;
