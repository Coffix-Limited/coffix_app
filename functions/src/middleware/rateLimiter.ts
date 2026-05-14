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

export const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  keyGenerator: (req) => ipKeyGenerator(req.ip ?? "unknown"),
  handler: tooManyRequestsResponse,
  standardHeaders: true,
  legacyHeaders: false,
});