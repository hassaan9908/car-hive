# Mutual Investment Feature - Workflow Diagrams

## 1. Investment Creation Workflow

```
User → Select Ad → Create Investment
                    ↓
            Set Investment Parameters
            (Goal, Min Contribution, Deadline)
                    ↓
            Validate Parameters
                    ↓
            Create Investment Vehicle Document
                    ↓
            Status: "open"
                    ↓
            Display in Investment Marketplace
```

## 2. Investment Flow

```
User → Browse Investments → Select Vehicle
                                ↓
                        View Investment Details
                        (Progress, Investors, Terms)
                                ↓
                        Enter Investment Amount
                                ↓
                    Validate Amount & Availability
                                ↓
                        Confirm Investment
                                ↓
                    Create Investment Document
                    Create Transaction (pending)
                                ↓
                        Process Payment
                                ↓
                    ┌───────────┴───────────┐
                    ↓                       ↓
            Payment Success          Payment Failed
                    ↓                       ↓
        Update Investment Status    Show Error Message
        Update Vehicle Investment   Transaction: "failed"
        Calculate Investment Ratio
        Check Funding Status
                    ↓
            ┌───────┴───────┐
            ↓               ↓
    Funding Complete   Funding Incomplete
            ↓               ↓
    Status: "funded"   Status: "open"
    Notify Investors   Continue Accepting
```

## 3. Profit Distribution Workflow

```
Vehicle Sold → Record Sale Price
                    ↓
            Calculate Total Profit
            (Sale Price - Investment - Expenses - Platform Fee)
                    ↓
            Get All Active Investments
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
Proportional Method      Equal Method
        ↓                       ↓
Profit × Ratio      Profit ÷ Investors
        ↓                       ↓
            Create Transaction for Each Investor
            (Type: profit_distribution, Status: pending)
                    ↓
            Process Payments to Investors
                    ↓
            ┌───────┴───────┐
            ↓               ↓
    Payment Success    Payment Failed
            ↓               ↓
    Update Investment   Retry Payment
    (totalProfitReceived)
    Transaction: "completed"
            ↓
    Notify Investors
    Update Vehicle Status: "sold"
```

## 4. Share Sale Workflow

```
Investor → My Investments → Select Investment
                                ↓
                        View Investment Details
                        (Current Shares, Value)
                                ↓
                        Click "Sell Shares"
                                ↓
                    Enter Sale Details
                    (Price, Description)
                                ↓
                    Validate Sale Price
                                ↓
            Create Share Marketplace Listing
            (Status: "active")
                                ↓
            Shares Appear in Marketplace
                                ↓
        ┌───────────────────────┴───────────────────────┐
        ↓                                               ↓
    Shares Purchased                            Listing Expires
        ↓                                               ↓
    Process Payment                            Remove Listing
    Transfer Ownership                         Status: "cancelled"
    Update Investment Documents
    Notify Seller & Buyer
```

## 5. Share Purchase Workflow

```
User → Marketplace → Browse Available Shares
                            ↓
                    Select Shares to Purchase
                            ↓
                    View Share Details
                    (Percentage, Price, Vehicle Info)
                            ↓
                    Confirm Purchase
                            ↓
            Validate Availability & Price
                            ↓
                    Process Payment
                            ↓
            ┌───────────────┴───────────────┐
            ↓                               ↓
    Payment Success                    Payment Failed
            ↓                               ↓
    Transfer Share Ownership          Show Error
    Update Investment Documents
    Create Transaction Records
    Notify Seller & Buyer
```

## 6. Investment Lifecycle States

```
[OPEN]
  ↓ (Investment Made)
[FUNDING]
  ↓ (Goal Reached)
[FUNDED]
  ↓ (Vehicle Purchased)
[ACTIVE]
  ↓ (Vehicle Sold)
[SOLD]
  ↓ (Profits Distributed)
[CLOSED]

Alternative Path:
[OPEN] → [EXPIRED] → [CLOSED] (Refunds Issued)
```

## 7. Investment Status Transitions

```
Investment Vehicle Status:
- open: Accepting investments
- funded: Investment goal reached
- closed: Deadline passed, not fully funded (refunds)
- sold: Vehicle sold, profits distributed

Investment Status:
- pending: Payment processing
- active: Investment confirmed
- sold: Shares sold to another investor
- refunded: Investment refunded (not fully funded)

Transaction Status:
- pending: Awaiting processing
- completed: Successfully processed
- failed: Processing failed
- refunded: Transaction refunded
```

## 8. Data Flow Diagram

```
┌─────────────────┐
│  Investment      │
│  Vehicle         │
│  (Collection)    │
└────────┬─────────┘
         │
         ├───→ Investments (Collection)
         │         │
         │         ├──→ Investment Transactions
         │         │
         │         └──→ Share Marketplace
         │
         └──→ Investment Transactions
                   │
                   └──→ Payment Gateway
```

## 9. User Journey Map

### Investor Journey:
1. **Discovery**: Browse investment opportunities
2. **Research**: View vehicle details, investment terms
3. **Decision**: Compare options, calculate potential returns
4. **Investment**: Enter amount, confirm, pay
5. **Tracking**: Monitor investment status, funding progress
6. **Profit**: Receive profit distributions
7. **Exit**: Sell shares or wait for vehicle sale

### Initiator Journey:
1. **Creation**: Create investment opportunity from ad
2. **Configuration**: Set investment parameters
3. **Promotion**: Share investment opportunity
4. **Monitoring**: Track funding progress
5. **Management**: Manage vehicle (if purchased)
6. **Sale**: Coordinate vehicle sale
7. **Distribution**: Profit distribution to investors

## 10. Key Decision Points

### Investment Validation:
- ✅ Amount >= minimum contribution
- ✅ Amount <= remaining needed
- ✅ Investment deadline not passed
- ✅ User authenticated
- ✅ Sufficient balance (if wallet)

### Profit Distribution:
- ✅ Vehicle marked as sold
- ✅ Sale price recorded
- ✅ All expenses calculated
- ✅ Platform fee deducted
- ✅ Profit > 0

### Share Sale:
- ✅ Investor owns shares
- ✅ Shares not already listed
- ✅ Price is reasonable
- ✅ Investment vehicle still active

### Share Purchase:
- ✅ Shares available
- ✅ Listing not expired
- ✅ User has sufficient balance
- ✅ Not purchasing own shares

---

## 11. Error Handling Scenarios

### Payment Failure:
```
Payment Failed
    ↓
Show Error Message
    ↓
Transaction Status: "failed"
    ↓
Allow Retry
    ↓
Or Cancel Investment
```

### Funding Incomplete:
```
Deadline Reached
    ↓
Check Funding Status
    ↓
If Not Fully Funded:
    ↓
Status: "closed"
    ↓
Refund All Investments
    ↓
Notify Investors
```

### Share Sale Failure:
```
Payment Failed During Share Purchase
    ↓
Rollback Transaction
    ↓
Keep Listing Active
    ↓
Notify Buyer of Failure
```

---

## 12. Notification Triggers

1. **Investment Created**: Notify potential investors
2. **Investment Made**: Notify initiator, update progress
3. **Funding Complete**: Notify all investors
4. **Vehicle Purchased**: Notify all investors
5. **Vehicle Sold**: Notify all investors
6. **Profit Distributed**: Notify each investor
7. **Shares Listed**: Notify potential buyers
8. **Shares Sold**: Notify seller and buyer
9. **Deadline Approaching**: Notify initiator and investors
10. **Investment Expired**: Notify all investors

---

This workflow document complements the implementation plan and provides visual guidance for understanding the feature's operation.

