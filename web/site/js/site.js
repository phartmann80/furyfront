(function () {
  const hero = document.getElementById("hero");
  const heroVideo = document.getElementById("hero-video");
  const trailerBtn = document.getElementById("watch-trailer");
  const trailerModal = document.getElementById("trailer-modal");
  const trailerPlayer = document.getElementById("trailer-player");
  const trailerClose = document.getElementById("trailer-close");
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function markNoVideo() {
    hero?.classList.add("no-video");
  }

  async function bootHeroVideo() {
    if (!heroVideo || reducedMotion) {
      markNoVideo();
      return;
    }

    try {
      heroVideo.muted = true;
      const playPromise = heroVideo.play();
      if (playPromise !== undefined) {
        await playPromise;
      }
    } catch {
      markNoVideo();
    }
  }

  function openTrailer() {
    if (!trailerModal || !trailerPlayer) return;
    trailerModal.showModal();
    trailerPlayer.currentTime = 0;
    trailerPlayer.muted = false;
    trailerPlayer.play().catch(() => {
      trailerPlayer.controls = true;
    });
  }

  function closeTrailer() {
    if (!trailerModal || !trailerPlayer) return;
    trailerPlayer.pause();
    trailerPlayer.currentTime = 0;
    trailerModal.close();
  }

  heroVideo?.addEventListener("error", markNoVideo);
  trailerBtn?.addEventListener("click", openTrailer);
  trailerClose?.addEventListener("click", closeTrailer);
  trailerModal?.addEventListener("cancel", closeTrailer);
  trailerModal?.addEventListener("click", (event) => {
    if (event.target === trailerModal) closeTrailer();
  });

  bootHeroVideo();
})();
