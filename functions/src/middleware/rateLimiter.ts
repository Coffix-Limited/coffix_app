import { Request, Response } from "express";
import { AuthenticatedRequest } from "./auth";
import { rateLimit, ipKeyGenerator } from "express-rate-limit";

const tooManyRequestsResponse = (_req: Request, res: Response) => {
  res.status(429).json({
    success: false,
    message: "Too many requests. Please try again later.",
  });
};

/** Keyed by Firebase UID when available, falls back to IP. */
const keyByUid = (req: Request): string => {
  const uid = (req as AuthenticatedRequest).user?.uid;
  return uid ?? ipKeyGenerator(req.ip ?? "unknown");
};

export const otpSendLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  keyGenerator: keyByUid,
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

export const otpVerifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  keyGenerator: keyByUid,
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

export const authLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 5,
  keyGenerator: (req) => ipKeyGenerator(req.ip ?? "unknown"),
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

export const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  keyGenerator: (req) => ipKeyGenerator(req.ip ?? "unknown"),
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

export const paymentLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  keyGenerator: keyByUid,
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

export const creditLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  keyGenerator: keyByUid,
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Paths exempt from the global limiter. `/log` is high-volume (the Flutter app
 * fires a log on nearly every navigation/action) and `/health` is for probes —
 * neither should consume the budget meant for real API calls.
 */
const globalLimiterExemptPaths = ["/log", "/health"];

export const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  // Generous ceiling: a single active user produces many requests/min. This is a
  // per-instance, in-memory limit (see note below), so keep it permissive.
  max: 300,
  // Key by Firebase UID when available so users behind a shared IP (e.g. café
  // wifi / NAT) aren't lumped into one bucket; fall back to IP for anonymous calls.
  keyGenerator: keyByUid,
  skip: (req) =>
    globalLimiterExemptPaths.some((p) => req.path.startsWith(p)),
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

// NOTE: express-rate-limit uses an in-memory store by default. With
// minInstances:1 / maxInstances:10 each Cloud Run instance keeps its own
// counter, so this limit is per-instance, not truly global. For correct global
// limiting across instances, back it with a shared store (Firestore/Redis).