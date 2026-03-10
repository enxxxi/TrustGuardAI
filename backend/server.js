console.log("Server file is running");

const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
    res.send("TrustGuard AI backend running");
});

app.listen(5000, () => {
    console.log("Server running on port 5000");
});