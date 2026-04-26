const r = require("express").Router();
const c = require("../controllers/clinicsController");
r.get("/", c.search);
module.exports = r;
