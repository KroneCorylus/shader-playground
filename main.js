const canvas = document.querySelector(".glslCanvas");
canvas.width = document.body.clientWidth;
canvas.height = document.body.clientHeight;
const sandbox = new GlslCanvas(canvas);
let previousCursor = { x: 0, y: 0, z: 10, w: 20 };
let currentCursor = { x: 0, y: 0, z: 10, w: 20 };
let option = 0;

fetch("/shaders/cursor_example.glsl")
  .then((response) => {
    return response.text();
  })
  .then((fragment) => {
    sandbox.load(fragment);
    gameLoop();
  });

function setCursorUniforms() {
  sandbox.setUniform(
    "iCursorCurrent",
    currentCursor.x,
    currentCursor.y,
    currentCursor.z,
    currentCursor.w,
  );
  sandbox.setUniform(
    "iCursorPrevious",
    previousCursor.x,
    previousCursor.y,
    previousCursor.z,
    previousCursor.w,
  );
  sandbox.setUniform("iTimeCursorChange", performance.now() / 1000);
}
function updateCursor() {
  previousCursor = { ...currentCursor };
  const z = 10;
  const w = 20;
  const x = Math.random() * canvas.width;
  const y = Math.random() * canvas.height;
  currentCursor = { x: x, y: y, z: z, w: w };
  setCursorUniforms();
}
function moveCursor(x, y) {
  y = canvas.height - y;
  previousCursor = { ...currentCursor };
  currentCursor = {
    x: x,
    y: y,
    z: 10,
    w: 20,
  };
  setCursorUniforms();
}

canvas.addEventListener("click", function () {
  change(1);
});
canvas.addEventListener("contextmenu", function (event) {
  event.preventDefault(); // Prevent the default context menu from appearing
  change(-1);
});

function gameLoop() {
  change(1);
  // setInterval(updateCursor, 3000); // Change every 10 seconds
}

function change(value) {
  let top = canvas.height * 0.1;
  let bottom = canvas.height * 0.9;
  let left = canvas.width * 0.1;
  let right = canvas.width * 0.9;

  option = (option + value) % 8;
  console.log(option);
  switch (option) {
    case 0:
      moveCursor(left, top);
      moveCursor(right, bottom);
      break;
    case 1:
      moveCursor(left, bottom);
      moveCursor(right, top);
      break;
    case 2:
      moveCursor(right, bottom);
      moveCursor(left, top);
      break;
    case 3:
      moveCursor(right, top);
      moveCursor(left, bottom);
      break;
    case 4:
      moveCursor(top, right);
      moveCursor(bottom, right);
      break;
    case 5:
      moveCursor(bottom, right);
      moveCursor(top, right);
      break;
    case 6:
      moveCursor(bottom, left);
      moveCursor(bottom, right);
      break;
    case 7:
      moveCursor(top, right);
      moveCursor(top, left);
      break;
  }
}
