const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/alertsController");
r.get("/",   c.getAll);
r.post("/",  auth, c.create);
module.exports = r;
