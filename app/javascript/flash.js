document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".flash-message .btn-close").forEach(button => {
    button.addEventListener("click", () => {
      const alert = button.closest(".alert");
      if (alert) {
        alert.style.transition = "opacity 0.5s";
        alert.style.opacity = "0";
        setTimeout(() => alert.remove(), 500);
      }
    });
  });
});
