(function () {
  const trailerBtn = document.getElementById("watch-trailer");
  const trailerModal = document.getElementById("trailer-modal");
  const trailerPlayer = document.getElementById("trailer-player");
  const trailerClose = document.getElementById("trailer-close");

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

  trailerBtn?.addEventListener("click", openTrailer);
  trailerClose?.addEventListener("click", closeTrailer);
  trailerModal?.addEventListener("cancel", closeTrailer);
  trailerModal?.addEventListener("click", (event) => {
    if (event.target === trailerModal) closeTrailer();
  });
})();
