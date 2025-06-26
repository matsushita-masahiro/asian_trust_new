document.addEventListener("DOMContentLoaded", () => {
  const fadeElems = document.querySelectorAll('.fadein');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry, index) => {
      if (entry.isIntersecting) {
        // 遅延表示：indexごとに 200ms ずつ遅らせて順番に表示
        setTimeout(() => {
          entry.target.classList.add('show');
        }, index * 200); // ← 遅延時間を調整
        observer.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.1
  });

  fadeElems.forEach(el => {
    observer.observe(el);
  });
});
