# Razorpay Integration - Payment Flow

## What Happens When User Clicks "Buy Now"

### 1️⃣ **Create Payment Order (Frontend → Backend)**
When user clicks "Buy Now", the app calls your backend to create a payment order:

```
Endpoint: POST /api/create-payment-order
Request Body:
{
  "user_id": 2,
  "plan_id": 1,
  "plan_name": "Premium Plan",
  "amount": 999,
  "currency": "INR",
  "email": "user@example.com",
  "phone": "919903215501"
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
- Test Key: `rzp_test_SUdRBcsuXaJvyM`

### 3️⃣ **User Completes Payment**
User enters payment details in Razorpay UI and completes payment

### 4️⃣ **Confirm Payment (Frontend → Backend)**
After successful payment, app calls backend to confirm:

```
Endpoint: POST /api/confirm-payment
Request Body:
{
  "user_id": 2,
  "plan_id": 1,
  "order_id": 1,
  "razorpay_order_id": "order_1A2B3C4D5E6F",
  "razorpay_payment_id": "pay_1A2B3C4D5E6F",
  "razorpay_signature": "9ef4dffbfd84f1318f6739a3ce19f9d85851857ae648f114332d8401e0949a3d",
  "amount": 999,
  "plan_name": "Premium Plan"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Payment confirmed and subscription activated"
}
```

---

## Data Sent to Backend

| Field | Type | Example | Purpose |
|-------|------|---------|---------|
| `user_id` | int | 2 | Identify which user |
| `plan_id` | int | 1 | Which subscription plan |
| `plan_name` | string | "Premium Plan" | Plan details |
| `amount` | int | 999 | Amount in INR |
| `currency` | string | "INR" | Currency |
| `email` | string | "user@example.com" | User email |
| `phone` | string | "919903215501" | User phone |
| `razorpay_order_id` | string | "order_1A2B3C..." | Razorpay order reference |
| `razorpay_payment_id` | string | "pay_1A2B3C..." | Razorpay payment ID |
| `razorpay_signature` | string | "9ef4dff..." | Signature for verification |

---

## Backend Implementation Checklist

- [ ] Create `/api/create-payment-order` endpoint
  - Accept user_id, plan_id, amount
  - Create order in Razorpay using Razorpay API
  - Return razorpay_order_id
  - Store order in database

- [ ] Create `/api/confirm-payment` endpoint
  - Verify Razorpay signature
  - Update user subscription in database
  - Mark order as paid
  - Return success confirmation

- [ ] Use Razorpay Keys:
  - Key ID: `rzp_test_SUdRBcsuXaJvyM` (test)
  - Key Secret: `y1Ip6i8ofpKgAQRlvmWzSKnA` (test)

---

## Testing the Flow

1. Click "Buy Now" on a subscription plan
2. App creates order on backend
3. Razorpay dialog opens with user details pre-filled
4. Pay with test Razorpay credentials
5. On success, app confirms payment with backend
6. User's subscription is activated

---

## Error Handling

The app handles:
- ✅ User not authenticated → Shows login prompt
- ✅ Backend order creation fails → Shows error message
- ✅ Razorpay payment fails → Shows error message
- ✅ Backend payment confirmation fails → Shows error message
- ✅ Network errors → Retry mechanism
