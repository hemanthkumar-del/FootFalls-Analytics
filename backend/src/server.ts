import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { connectDatabase } from './config/database';
import { errorHandler } from './middleware/errorHandler';
import routes from './routes';

const app = express();

// Connect to MongoDB
connectDatabase();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Rate Limiting
const limiter = rateLimit({
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
  servers: [{ url: `http://localhost:${env.PORT}/api` }],
  paths: {},
};
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Routes
app.use('/api', routes);

// Error Handling
app.use(errorHandler);

app.listen(env.PORT, () => {
  console.log(`Server running on port ${env.PORT}`);
  console.log(`Swagger docs available at http://localhost:${env.PORT}/api-docs`);
});

export default app;
