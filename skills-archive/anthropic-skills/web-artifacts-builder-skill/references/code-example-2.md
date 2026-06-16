# Code Example 2

From: SKILL.md

```html
<!DOCTYPE html>
<html>
  <head>
    <style>
      * {
        box-sizing: border-box;
      }
      body {
        display: grid;
        place-items: center;
        min-height: 100vh;
        margin: 0;
        background: #0f172a;
        color: #f8fafc;
        font-family: system-ui;
      }
      button {
        background: #3b82f6;
        color: white;
        border: none;
        padding: 1rem 2rem;
        font-size: 1.5rem;
        border-radius: 8px;
        cursor: pointer;
        transition: transform 0.1s;
      }
      button:active {
        transform: scale(0.95);
      }
      .result {
        font-size: 3rem;
        font-weight: bold;
      }
    </style>
  </head>
  <body>
    <div style="text-align:center">
      <div class="result" id="r">0</div>
      <div style="margin-top:1rem">
        <button onclick="r.textContent=eval(r.textContent)">=</button>
      </div>
    </div>
  </body>
</html>
```
