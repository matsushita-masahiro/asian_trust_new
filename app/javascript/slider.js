document.addEventListener("turbo:load", () => {
  const el = document.querySelector('#carouselExample');
  if (el) {
    new bootstrap.Carousel(el, {
      interval: 5000,
      ride: 'carousel',
      pause: false,
      wrap: true
    });
  }
});
