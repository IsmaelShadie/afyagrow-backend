const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/remindersController");
r.get("/",        auth, c.getAll);
r.post("/",       auth, c.create);
r.delete("/:id",  auth, c.remove);
module.exports = r;
