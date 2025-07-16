document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll(".clickable-row").forEach(function(row) {
    row.style.cursor = "pointer";
    row.addEventListener("click", function() {
      const url = row.dataset.href;
      if (url) window.location.href = url;
    });
  });
});
