import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

import userRoutes from "./routes/user.routes.js";
import productRoutes from "./routes/product.routes.js";
import favoriteRoutes from "./routes/favorite.routes.js";
import cartRoutes from "./routes/cart.routes.js";
import orderRoutes from "./routes/order.routes.js";
dotenv.config(); // Đọc file .env

const app = express();
app.use(cors());
app.use(express.json());

// 🧩 Dòng này giúp Express phục vụ ảnh tĩnh trong thư mục /uploads
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ✅ Kết nối MongoDB
const MONGO_URI = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/mydb";
mongoose
  .connect(MONGO_URI)
  .then(() => console.log("✅ Kết nối MongoDB thành công"))
  .catch((err) => {
    console.error("❌ Lỗi kết nối MongoDB:", err.message);
    process.exit(1);
  });

// ✅ Đăng ký Router
app.use("/api/products", productRoutes);
app.use("/api/users", userRoutes);
app.use("/api/favorites", favoriteRoutes);
app.use("/api/cart", cartRoutes);
app.use("/api/orders", orderRoutes);
// ✅ Test route
app.get("/", (req, res) => {
  res.send("🚀 API đang chạy ngon lành!");
});

// ✅ Chạy server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🔥 Server đang chạy tại cổng ${PORT}`));
