const r   = require("express").Router();
const opt = require("../middleware/optionalAuth");
const c   = require("../controllers/sosController");
r.post("/trigger", opt, c.trigger);
module.exports = r;
