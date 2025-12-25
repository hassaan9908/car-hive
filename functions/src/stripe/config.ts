import * as functions from 'firebase-functions';
import Stripe from 'stripe';

// Initialize Stripe with secret key from environment
const stripeSecretKey = functions.config().stripe?.secret_key || 
  process.env.STRIPE_SECRET_KEY || 
  'sk_test_51SgTrF06P57eoMHkChFF5ioQ8SkLdAZV6phUsF7oV9IOCzKEmfMFZDr2zMCpuKsQ7Cxmf9hQ2mcl0VUCqKdVwjiL00mBoVQl9c';

export const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2023-10-16',
});

// Stripe webhook secret (set in Firebase config or environment)
export const webhookSecret = functions.config().stripe?.webhook_secret || 
  process.env.STRIPE_WEBHOOK_SECRET || 
  '';

