const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/vitalsController");
r.get("/",   auth, c.getAll);
r.post("/",  auth, c.create);
module.exports = r;
