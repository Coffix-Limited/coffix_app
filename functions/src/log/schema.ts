import { z } from "zod";

const createLogSchema = z.object({
  action: z.string().min(1),
  category: z.string().min(1),
  severityLevel: z.enum(["1", "2", "3", "4", "5", "6", "7", "8", "9"]),
  notes: z.string().min(1),
  page: z.string().optional(),
  userId: z.string().optional(),
  customerId: z.string().optional(),
});

export default createLogSchema;
