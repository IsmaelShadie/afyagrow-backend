const r    = require("express").Router();
const opt  = require("../middleware/optionalAuth");
const c    = require("../controllers/chatController");
r.post("/", opt, c.chat);
module.exports = r;
