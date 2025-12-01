import dotenv from "dotenv";

dotenv.config();

export const envConfig = {
  port: parseInt(process.env.BACKEND_PORT || "3847", 10),
  mongo: {
    uri: process.env.MONGO_URI || "",
    dbName: process.env.MONGO_DATABASE,
  },
} as const;
