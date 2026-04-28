const r    = require("express").Router();
const auth = require("../middleware/auth");
const c    = require("../controllers/hmisController");
r.get("/",   auth, c.getAll);
r.post("/",  auth, c.submit);
module.exports = r;
