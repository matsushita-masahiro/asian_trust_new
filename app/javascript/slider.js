document.addEventListener("turbo:load", () => {
  const slides = document.querySelectorAll("#custom-slider .slide");
  const dots = document.querySelectorAll("#slider-dots .dot"); // ← ドット取得
  let current = 0;
  const interval = 5000;

  const showSlide = (index) => {
    slides.forEach((slide, i) => {
      slide.classList.toggle("active", i === index);
    });

    // 🔘 ドットのアクティブ切替
    dots.forEach((dot, i) => {
      dot.classList.toggle("active", i === index);
    });
  };

  // 🔘 ドットクリックでスライド切り替え
  dots.forEach((dot, index) => {
    dot.addEventListener("click", () => {
      current = index;
      showSlide(current);
    });
  });

  // 初期表示
  showSlide(current);

  // 自動切り替え
  setInterval(() => {
    current = (current + 1) % slides.length;
    showSlide(current);
  }, interval);
});
