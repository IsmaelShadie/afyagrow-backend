const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/referralsController");
r.get("/",        auth, c.getAll);
r.post("/",       auth, c.create);
r.put("/:id",     auth, c.updateStatus);
module.exports = r;
