import { z } from "zod";

const createLogSchema = z.object({
  action: z.string().min(1),
  category: z.string().min(1),
  severityLevel: z.number().min(1).max(9),
  notes: z.string().min(1),
  page: z.string().optional(),
  userId: z.string().optional(),
  customerId: z.string().optional(),
});

export default createLogSchema;
