import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => ({
  plugins: [react()],
  server: {
    port: 5173
  },
  // Use root in dev/preview, subpath on production builds for GitHub Pages
  // Adjusted for repo name: pickleball-tournament
  base: mode === "production" ? "/pickleball-tournament/" : "/"
}));
