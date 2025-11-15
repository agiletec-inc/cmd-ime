import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { greet, setupGreetForm } from "./main.js";

beforeEach(() => {
  window.__TAURI__ = {
    core: {
      invoke: vi.fn().mockResolvedValue("こんにちは Foo"),
    },
  };

  document.body.innerHTML = `
    <form id="greet-form">
      <input id="greet-input" />
      <button type="submit">送信</button>
    </form>
    <p id="greet-msg"></p>
  `;

  setupGreetForm(document);
});

describe("greet form", () => {
  it("invokes tauri command and renders response", async () => {
    const input = document.querySelector("#greet-input");
    input.value = "Foo";

    const form = document.querySelector("#greet-form");
    form.dispatchEvent(new Event("submit", { cancelable: true, bubbles: true }));

    await Promise.resolve();
    await Promise.resolve();

    expect(window.__TAURI__.core.invoke).toHaveBeenCalledWith("greet", {
      name: "Foo",
    });

    const message = document.querySelector("#greet-msg");
    expect(message.textContent).toBe("こんにちは Foo");
  });
});
