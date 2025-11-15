let greetInputEl;
let greetMsgEl;

function tauriInvoke() {
  if (!window.__TAURI__?.core?.invoke) {
    throw new Error("Tauri runtime is unavailable");
  }
  return window.__TAURI__.core.invoke;
}

export async function greet() {
  greetMsgEl.textContent = await tauriInvoke()("greet", {
    name: greetInputEl.value,
  });
}

export function setupGreetForm(doc = document) {
  greetInputEl = doc.querySelector("#greet-input");
  greetMsgEl = doc.querySelector("#greet-msg");
  doc.querySelector("#greet-form").addEventListener("submit", (e) => {
    e.preventDefault();
    greet();
  });
}

window.addEventListener("DOMContentLoaded", () => {
  setupGreetForm();
});
