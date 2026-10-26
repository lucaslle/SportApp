{{flutter_js}}
{{flutter_build_config}}

// On large screens the app runs inside the iPhone frame of index.html; on phones it fills the screen.
const framed = window.matchMedia('(min-width: 720px) and (min-height: 600px)').matches;
if (framed) {
  const url = new URL(window.location.href);
  url.searchParams.set('frame', 'iphone');
  window.history.replaceState(null, '', url);
}
document.body.classList.toggle('framed', framed);

_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: document.querySelector('#flutter-host'),
    });
    await appRunner.runApp();
  },
});
