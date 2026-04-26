const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/pregnancyController");
r.get("/",       auth, c.get);
r.post("/",      auth, c.create);
r.post("/anc",   auth, c.addANC);
module.exports = r;
