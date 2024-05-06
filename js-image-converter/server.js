const express      = require("express");
const fileUpload   = require("express-fileupload");
const path         = require("path");
const { v4: uuid } = require("uuid");
const sharp        = require("sharp");

const app  = express();
const port = 3000;

app.get("/", function(req, resp) {
  resp.sendFile(path.join(__dirname, "/index.html"));
});

app.use(fileUpload({ useTempFiles: false }));

app.use("/images", express.static(path.join(__dirname, "images")));

app.post("/upload", async function(req, resp) {
  return resp.status(500).send(`Sorry, no thanks`);

  if (!req.files || Object.keys(req.files).length === 0) {
    return resp.status(400).send(`<div>No files were uploaded.</div>`);
  }

  const filename = path.parse(req.files.image.name).name;
  const newPath = `./images/${filename}-${uuid()}.jpg`;

  await sharp(req.files.image.data)
    .jpeg()
    .toFile(newPath)
  ;

  resp.send(`<img src="${newPath}" />`);
});


app.listen(port, () => {
  console.log(`Listening on ${port}`);
});
