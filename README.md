
  
  

  
  
  購入
  curl -X POST https://asiantrust-e236e749fb27.herokuapp.com/lstep/purchase \
  -H "Content-Type: application/json" \
  -H "X-LSTEP-SECRET: test_token_123" \
  -d '{
    "referrer_id": "lstep_0038",
    "product_id": 4,
    "unit_price": 30000,
    "quantity": 10,
    "customer_name": "Heroku 太郎",
    "customer_email": "heroku.taro@example.com",
    "customer_phone": "08099999999",
    "customer_address": "川崎市高津区溝口1-1"
  }'
  