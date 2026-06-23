export interface LogSettings {
  docId?: string;
  retentionDays?: number;
  updatedAt?: Date;
  levels: number[];
  enabled: boolean;
}