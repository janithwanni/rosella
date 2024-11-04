Shiny.addCustomMessageHandler("setup-cf-par-coord", setup_par_coord)
Shiny.addCustomMessageHandler("toggle-highlight-cf-path", toggle_highlight_path)

async function waitForElement(selector) {
  while (!document.querySelector(selector)) {
    await new Promise(resolve => requestAnimationFrame(resolve));
  }
  return document.querySelector(selector);
}

Shiny.addCustomMessageHandler("about-to-render-cfvec-detour", function(message) {
  (async () => {
    const element = await waitForElement(`#${message.id}`);
    Shiny.setInputValue(
      `${message.ns}cfvec_detour_rendered`, {is_rendered: true}, {priority: 'event'}
    )
  })();
})