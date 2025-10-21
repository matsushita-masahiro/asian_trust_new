// Order page JavaScript functionality

// Direct purchase function for products
window.directPurchase = function(productId) {
  const card = event.target.closest('.card-body');
  const quantitySelect = card.querySelector('select[name="quantity"]');
  const quantity = quantitySelect.value;
  
  if (!quantity) {
    alert('数量を選択してください');
    return;
  }
  
  // Get the checkout path from the container's data attribute
  const container = document.querySelector('.container[data-checkout-path]');
  const checkoutPath = container ? container.dataset.checkoutPath : '/orders/checkout';
  
  // 今すぐ購入用のフォームを動的に作成して送信
  const form = document.createElement('form');
  form.method = 'GET';
  form.action = checkoutPath;
  
  const productIdInput = document.createElement('input');
  productIdInput.type = 'hidden';
  productIdInput.name = 'product_id';
  productIdInput.value = productId;
  
  const quantityInput = document.createElement('input');
  quantityInput.type = 'hidden';
  quantityInput.name = 'quantity';
  quantityInput.value = quantity;
  
  form.appendChild(productIdInput);
  form.appendChild(quantityInput);
  document.body.appendChild(form);
  form.submit();
};