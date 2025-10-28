export default {
  content: ["./index.html", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        courtAvailable: "#22c55e", // green
        courtInPlay: "#eab308", // yellow
        courtWaiting: "#ef4444" // red
      }
    }
  },
  plugins: []
};
