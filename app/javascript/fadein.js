document.addEventListener("turbo:load", () => {
  // ✨ Fadein 初期化（Turbo対応）
    const fadeElems = document.querySelectorAll('.fadein');
  
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          // それぞれに data-delay を使って遅延表示
          const delay = parseInt(entry.target.dataset.delay) || 0;
          setTimeout(() => {
            entry.target.classList.add('show');
          }, delay);
          observer.unobserve(entry.target);
        }
      });
    }, {
      threshold: 0.1
    });
  
    fadeElems.forEach((el, i) => {
      el.dataset.delay = i * 200; // ← 200ms刻みで遅延
      observer.observe(el);
    });
  });

