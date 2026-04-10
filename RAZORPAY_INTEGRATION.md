# Razorpay Integration - Payment Flow

## What Happens When User Clicks "Buy Now"

### 1️⃣ **Create Payment Order (Frontend → Backend)**
When user clicks "Buy Now", the app calls your backend to create a payment order:

```
Endpoint: POST http://localhost:8000/api/create-order
Request Body:
{
  "user_id": 1,
  "subscription_id": 2,
  "amount": 499
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "order_id": 1,
    "razorpay_order_id": "order_1A2B3C4D5E6F"
  }
}
```

### 2️⃣ **Open Razorpay Payment**
After backend returns order ID, the app opens Razorpay with:
- Razorpay Order ID (from backend)
- Amount in paise
- User name, email, phone (auto-filled)
- Live Key: `rzp_live_Sa6AlzKM1BdMum`

### 3️⃣ **User Completes Payment**
User enters payment details in Razorpay UI and completes payment

### 4️⃣ **Verify Payment (Frontend → Backend)**
After successful payment, app calls backend to verify:

```
Endpoint: POST http://localhost:8000/api/verify-payment
Request Body:
{
  "razorpay_order_id": "order_ABC123",
  "razorpay_payment_id": "pay_ABC123",
  "razorpay_signature": "generated_signature"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Payment verified and subscription activated"
}
```

---

## Data Sent to Backend

### Endpoint 1: Create Order

| Field | Type | Example | Purpose |
|-------|------|---------|---------|
| `user_id` | int | 1 | Identify which user |
| `subscription_id` | int | 2 | Which subscription to activate |
| `amount` | number | 499 | Amount in INR |

### Endpoint 2: Verify Payment

| Field | Type | Example | Purpose |
|-------|------|---------|---------|
| `razorpay_order_id` | string | "order_1A2B3C..." | Razorpay order reference |
| `razorpay_payment_id` | string | "pay_1A2B3C..." | Razorpay payment ID |
| `razorpay_signature` | string | "9ef4dff..." | Signature for verification |

---

## Backend Implementation Checklist

- [ ] Create `POST /api/create-order` endpoint
  - Accept user_id, subscription_id, amount
  - Create order in Razorpay using Razorpay API
  - Return success with order_id and razorpay_order_id
  - Store order in database with user_id and subscription_id

- [ ] Create `POST /api/verify-payment` endpoint
  - Accept razorpay_order_id, razorpay_payment_id, razorpay_signature
  - Verify Razorpay signature for security
  - Update user subscription in database
  - Mark order as paid
  - Return success confirmation

- [ ] Use Razorpay Keys:
  - Key ID: `rzp_live_Sa6AlzKM1BdMum` (production)
  - Key Secret: `kmiuExnFYGWl51aPzms46geG` (production)

---

## Testing the Flow

1. Click "Buy Now" on a subscription plan
2. App creates order on backend via `/api/create-order`
3. Razorpay dialog opens with user details pre-filled
4. Pay with test Razorpay credentials
5. On success, app verifies payment with backend via `/api/verify-payment`
6. User's subscription is activated

---

## Error Handling

The app handles:
- ✅ User not authenticated → Shows login prompt
- ✅ Backend order creation fails → Shows error message
- ✅ Razorpay payment fails → Shows error message
- ✅ Backend payment verification fails → Shows error message
- ✅ Network errors → Retry mechanism
