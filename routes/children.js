const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/childrenController");
r.get("/",              auth, c.getAll);
r.post("/",             auth, c.create);
r.put("/:id/vaccines",  auth, c.updateVaccines);
module.exports = r;
