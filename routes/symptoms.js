const r   = require("express").Router();
const opt = require("../middleware/optionalAuth");
const c   = require("../controllers/symptomsController");
r.post("/check", opt, c.check);
module.exports = r;
