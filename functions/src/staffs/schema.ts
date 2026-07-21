import { z } from "zod";

export const createStaffSchema = z.object({
  email: z.email(),
  role: z.string().min(1, "role is required"),
  storeIds: z.array(z.string()).optional().default([]),
  firstName: z.string().optional(),
  lastName: z.string().optional(),
});

export type CreateStaffSchema = z.infer<typeof createStaffSchema>;
