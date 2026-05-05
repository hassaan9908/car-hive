# Mutual Investment Feature - Implementation Plan

## Overview
This document outlines the complete structure, workflow, and implementation approach for the Mutual Investment feature in the CarHive application. This feature allows multiple users to invest in vehicles together, share profits based on investment ratios, and provides mechanisms for investors to sell their shares or participate in vehicle resale.

---

## 1. Database Structure

### 1.1 Firestore Collections

#### Collection: `investment_vehicles`
Stores vehicles available for mutual investment.

```javascript
{
  id: "vehicle_investment_id",
  // Vehicle Details (from AdModel)
  adId: "reference_to_ads_collection",
  title: "Toyota Corolla 2020",
  price: "2500000", // Total vehicle price
  location: "Lahore",
  year: "2020",
  mileage: "50000",
  fuel: "Petrol",
  imageUrls: ["url1", "url2"],
  images360Urls: ["url1"],
  
  // Investment Details
  totalInvestmentGoal: 2500000, // Total amount needed
  minimumContribution: 50000, // Minimum investment per investor
  currentInvestment: 1500000, // Total invested so far
  investmentStatus: "open" | "funded" | "closed" | "sold", // Status of investment
  fundedAt: Timestamp, // When fully funded
  closedAt: Timestamp, // When investment closed
  
  // Ownership
  initiatorUserId: "user_id", // User who created the investment
  vehicleOwnerId: "user_id", // Original vehicle owner (if different)
  
  // Profit Distribution Settings
  profitDistributionMethod: "proportional" | "equal", // How profits are distributed
  platformFeePercentage: 5.0, // Platform fee (e.g., 5%)
  
  // Vehicle Status
  vehicleStatus: "pending" | "purchased" | "maintenance" | "rented" | "sold",
  purchaseDate: Timestamp,
  saleDate: Timestamp,
  salePrice: 0, // Final sale price
  
  // Metadata
  createdAt: Timestamp,
  updatedAt: Timestamp,
  expiresAt: Timestamp, // Investment deadline
  description: "Investment opportunity description"
}
```

#### Collection: `investments`
Stores individual investment records.

```javascript
{
  id: "investment_id",
  vehicleInvestmentId: "reference_to_investment_vehicles",
  userId: "investor_user_id",
  
  // Investment Details
  amount: 100000, // Amount invested
  investmentRatio: 0.04, // Percentage ownership (amount / totalInvestmentGoal)
  investmentDate: Timestamp,
  
  // Status
  status: "pending" | "active" | "sold" | "refunded",
  
  // Share Sale
  sharesForSale: false,
  sharesForSalePrice: 0, // Price at which investor wants to sell
  sharesForSaleDate: Timestamp,
  
  // Profit Tracking
  totalProfitReceived: 0,
  lastProfitDistributionDate: Timestamp,
  
  // Metadata
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### Collection: `investment_transactions`
Tracks all financial transactions related to investments.

```javascript
{
  id: "transaction_id",
  vehicleInvestmentId: "reference_to_investment_vehicles",
  investmentId: "reference_to_investments", // Null for vehicle-level transactions
  userId: "user_id",
  
  // Transaction Details
  type: "investment" | "profit_distribution" | "share_sale" | "share_purchase" | "refund",
  amount: 100000,
  status: "pending" | "completed" | "failed" | "refunded",
  
  // Payment Details
  paymentMethod: "jazzcash" | "easypay" | "bank_transfer" | "card",
  paymentReference: "transaction_reference",
  
  // Profit Distribution Specific
  profitAmount: 0, // For profit distribution transactions
  distributionDate: Timestamp,
  
  // Share Sale/Purchase Specific
  sharePrice: 0, // For share transactions
  sharePercentage: 0.0,
  
  // Metadata
  createdAt: Timestamp,
  completedAt: Timestamp,
  notes: "Transaction notes"
}
```

#### Collection: `share_marketplace`
Marketplace for buying/selling investment shares.

```javascript
{
  id: "listing_id",
  investmentId: "reference_to_investments",
  vehicleInvestmentId: "reference_to_investment_vehicles",
  sellerUserId: "user_id",
  
  // Share Details
  sharePercentage: 0.04,
  askingPrice: 120000, // Price seller wants
  originalInvestment: 100000, // Original investment amount
  
  // Status
  status: "active" | "sold" | "cancelled",
  
  // Sale Details
  buyerUserId: "user_id", // Null until sold
  soldAt: Timestamp,
  soldPrice: 0,
  
  // Metadata
  listedAt: Timestamp,
  expiresAt: Timestamp, // Listing expiration
  description: "Why selling shares"
}
```

---

## 2. Data Models

### 2.1 InvestmentVehicleModel
**File:** `lib/models/investment_vehicle_model.dart`

```dart
class InvestmentVehicleModel {
  final String id;
  final String adId;
  final String title;
  final String price;
  final String location;
  final String year;
  final String mileage;
  final String fuel;
  final List<String>? imageUrls;
  final List<String>? images360Urls;
  
  // Investment fields
  final double totalInvestmentGoal;
  final double minimumContribution;
  final double currentInvestment;
  final String investmentStatus; // open, funded, closed, sold
  final DateTime? fundedAt;
  final DateTime? closedAt;
  
  final String initiatorUserId;
  final String? vehicleOwnerId;
  
  final String profitDistributionMethod;
  final double platformFeePercentage;
  
  final String vehicleStatus;
  final DateTime? purchaseDate;
  final DateTime? saleDate;
  final double salePrice;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final String? description;
}
```

### 2.2 InvestmentModel
**File:** `lib/models/investment_model.dart`

```dart
class InvestmentModel {
  final String id;
  final String vehicleInvestmentId;
  final String userId;
  
  final double amount;
  final double investmentRatio;
  final DateTime investmentDate;
  
  final String status;
  
  final bool sharesForSale;
  final double? sharesForSalePrice;
  final DateTime? sharesForSaleDate;
  
  final double totalProfitReceived;
  final DateTime? lastProfitDistributionDate;
  
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 2.3 InvestmentTransactionModel
**File:** `lib/models/investment_transaction_model.dart`

```dart
class InvestmentTransactionModel {
  final String id;
  final String vehicleInvestmentId;
  final String? investmentId;
  final String userId;
  
  final String type;
  final double amount;
  final String status;
  
  final String? paymentMethod;
  final String? paymentReference;
  
  final double? profitAmount;
  final DateTime? distributionDate;
  
  final double? sharePrice;
  final double? sharePercentage;
  
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
}
```

### 2.4 ShareMarketplaceModel
**File:** `lib/models/share_marketplace_model.dart`

```dart
class ShareMarketplaceModel {
  final String id;
  final String investmentId;
  final String vehicleInvestmentId;
  final String sellerUserId;
  
  final double sharePercentage;
  final double askingPrice;
  final double originalInvestment;
  
  final String status;
  
  final String? buyerUserId;
  final DateTime? soldAt;
  final double? soldPrice;
  
  final DateTime listedAt;
  final DateTime? expiresAt;
  final String? description;
}
```

---

## 3. Services Layer

### 3.1 InvestmentVehicleService
**File:** `lib/services/investment_vehicle_service.dart`

**Key Methods:**
- `createInvestmentVehicle()` - Create new investment opportunity
- `getInvestmentVehicles()` - Get all available investments
- `getInvestmentVehicleById()` - Get specific investment details
- `updateInvestmentStatus()` - Update investment status
- `checkFundingComplete()` - Check if funding goal reached
- `markVehiclePurchased()` - Mark vehicle as purchased
- `markVehicleSold()` - Mark vehicle as sold with sale price

### 3.2 InvestmentService
**File:** `lib/services/investment_service.dart`

**Key Methods:**
- `createInvestment()` - User invests in a vehicle
- `getUserInvestments()` - Get all investments for a user
- `getInvestmentById()` - Get specific investment
- `getInvestorsForVehicle()` - Get all investors for a vehicle
- `calculateInvestmentRatio()` - Calculate ownership percentage
- `listSharesForSale()` - List shares on marketplace
- `cancelShareSale()` - Cancel share listing
- `purchaseShares()` - Buy shares from marketplace

### 3.3 ProfitDistributionService
**File:** `lib/services/profit_distribution_service.dart`

**Key Methods:**
- `calculateProfitDistribution()` - Calculate profit for each investor
- `distributeProfits()` - Automatically distribute profits to investors
- `getProfitHistory()` - Get profit distribution history
- `calculatePlatformFee()` - Calculate platform fee
- `processProfitDistribution()` - Process and record profit payments

### 3.4 InvestmentTransactionService
**File:** `lib/services/investment_transaction_service.dart`

**Key Methods:**
- `createTransaction()` - Create transaction record
- `updateTransactionStatus()` - Update transaction status
- `getUserTransactions()` - Get transaction history for user
- `getVehicleTransactions()` - Get all transactions for a vehicle
- `processPayment()` - Process payment (integrate with payment gateway)

### 3.5 ShareMarketplaceService
**File:** `lib/services/share_marketplace_service.dart`

**Key Methods:**
- `listShares()` - List shares for sale
- `getAvailableShares()` - Get all available shares for a vehicle
- `purchaseShares()` - Purchase shares from marketplace
- `cancelListing()` - Cancel share listing
- `getShareListings()` - Get all share listings

---

## 4. UI Components & Pages

### 4.1 Main Investment Page
**File:** `lib/pages/mutualinvestment.dart` (Update existing)

**Features:**
- List all available investment vehicles
- Filter by status (open, funded, closed, sold)
- Search investments
- Show investment progress (funding percentage)
- Display minimum contribution and total goal
- Quick invest button

**Sections:**
1. **Investment Opportunities Tab**
   - Grid/List view of available vehicles
   - Progress bars showing funding status
   - Quick stats (total invested, remaining, days left)

2. **My Investments Tab**
   - User's active investments
   - Investment value and current status
   - Profit received summary
   - Quick actions (view details, sell shares)

3. **Marketplace Tab**
   - Available shares for purchase
   - Filter by vehicle
   - Price comparison (asking vs original)

### 4.2 Investment Detail Page
**File:** `lib/pages/investment_detail_page.dart`

**Features:**
- Full vehicle details (images, 360 view, specs)
- Investment progress visualization
- List of current investors
- Investment form (amount input, validation)
- Investment terms and conditions
- Profit distribution calculator
- Share marketplace section

**Components:**
- `InvestmentProgressWidget` - Progress bar with stats
- `InvestorListWidget` - List of investors
- `InvestmentFormWidget` - Investment input form
- `ProfitCalculatorWidget` - Calculate potential profit
- `ShareMarketplaceWidget` - Available shares

### 4.3 My Investment Detail Page
**File:** `lib/pages/my_investment_detail_page.dart`

**Features:**
- User's investment details
- Current value and profit received
- Investment timeline
- Option to list shares for sale
- Transaction history
- Profit distribution history

**Components:**
- `InvestmentSummaryWidget` - Investment overview
- `ProfitHistoryWidget` - Profit received over time
- `TransactionHistoryWidget` - All transactions
- `SellSharesWidget` - Form to list shares

### 4.4 Share Marketplace Page
**File:** `lib/pages/share_marketplace_page.dart`

**Features:**
- Browse available shares
- Filter and search
- Share details (percentage, price, vehicle info)
- Purchase shares functionality
- My listings (shares I'm selling)

### 4.5 Investment Creation Page
**File:** `lib/pages/create_investment_page.dart`

**Features:**
- Select existing ad or create new
- Set investment goal and minimum contribution
- Set investment deadline
- Configure profit distribution method
- Review and publish

---

## 5. Workflow & Business Logic

### 5.1 Creating an Investment Opportunity

**Flow:**
1. User selects an existing ad or creates a new ad
2. User clicks "Create Investment Opportunity"
3. System validates:
   - User is authenticated
   - Ad exists and is active
   - User owns the ad OR has permission
4. User sets:
   - Total investment goal (can be less than vehicle price)
   - Minimum contribution per investor
   - Investment deadline (expiresAt)
   - Profit distribution method
5. System creates `investment_vehicle` document
6. Status set to "open"
7. Investment appears in marketplace

### 5.2 Making an Investment

**Flow:**
1. User browses investment opportunities
2. User selects a vehicle
3. System displays:
   - Current funding status
   - Remaining amount needed
   - Minimum contribution
   - Investment deadline
4. User enters investment amount
5. System validates:
   - Amount >= minimum contribution
   - Amount <= remaining needed
   - User has sufficient balance (if wallet system)
   - Investment hasn't expired
6. User confirms investment
7. System creates:
   - `investment` document
   - `investment_transaction` document (type: "investment", status: "pending")
8. Process payment (integrate payment gateway)
9. On payment success:
   - Update transaction status to "completed"
   - Update `investment_vehicle.currentInvestment`
   - Calculate and update `investment.investmentRatio`
   - Check if funding complete
10. If funding complete:
    - Update `investment_vehicle.investmentStatus` to "funded"
    - Set `fundedAt` timestamp
    - Notify initiator and all investors

### 5.3 Profit Distribution (Automated)

**Trigger:** When vehicle is sold

**Flow:**
1. Admin or initiator marks vehicle as sold
2. System records sale price
3. Calculate total profit:
   ```
   totalProfit = salePrice - totalInvestmentGoal - expenses - platformFee
   ```
4. For each investor (based on `profitDistributionMethod`):
   - **Proportional:** `investorProfit = totalProfit * investmentRatio`
   - **Equal:** `investorProfit = totalProfit / numberOfInvestors`
5. Create `investment_transaction` for each investor:
   - type: "profit_distribution"
   - amount: investorProfit
   - status: "pending"
6. Process payments to investors
7. Update `investment.totalProfitReceived` for each investor
8. Update `investment_vehicle.vehicleStatus` to "sold"
9. Notify all investors of profit distribution

**Automation Options:**
- Cloud Function triggered on vehicle sale
- Scheduled function to check for pending distributions
- Manual trigger by admin

### 5.4 Selling Shares (Secondary Market)

**Flow:**
1. Investor navigates to "My Investments"
2. Selects an investment
3. Clicks "Sell My Shares"
4. System displays:
   - Current share percentage
   - Original investment amount
   - Current vehicle value (if available)
5. Investor sets:
   - Asking price for shares
   - Optional description
6. System creates `share_marketplace` document:
   - status: "active"
   - listedAt: now
   - expiresAt: now + 30 days (configurable)
7. Shares appear in marketplace
8. Other users can purchase shares

### 5.5 Purchasing Shares from Marketplace

**Flow:**
1. User browses share marketplace
2. User selects shares to purchase
3. System displays:
   - Share percentage
   - Asking price
   - Vehicle details
   - Original investment amount
4. User confirms purchase
5. System validates:
   - Shares still available
   - Listing hasn't expired
   - User has sufficient balance
6. Process payment
7. On success:
   - Create `investment_transaction` (type: "share_purchase")
   - Update `investment`:
     - Transfer ownership: `userId` = buyer
     - Update `investmentRatio` (if partial purchase)
     - Set `sharesForSale` = false
   - Update `share_marketplace`:
     - status: "sold"
     - buyerUserId: buyer
     - soldAt: now
     - soldPrice: purchase price
   - Create new `investment` for buyer (or update existing)
   - Notify seller and buyer

### 5.6 Investment Refund (If Not Fully Funded)

**Flow:**
1. Investment deadline expires
2. System checks if `currentInvestment < totalInvestmentGoal`
3. If not fully funded:
   - Update `investment_vehicle.investmentStatus` to "closed"
   - For each investment:
     - Create `investment_transaction` (type: "refund")
     - Process refund to investor
     - Update `investment.status` to "refunded"
   - Notify all investors

---

## 6. Integration Points

### 6.1 Payment Gateway Integration
- Integrate JazzCash, EasyPay, or other payment methods
- Handle payment callbacks
- Update transaction status based on payment result
- Implement refund mechanism

### 6.2 Notification System
- Push notifications for:
  - Investment funded
  - Profit distributed
  - Shares sold
  - Investment deadline approaching
- Email notifications for important events

### 6.3 Activity Logging
- Log all investment activities
- Track user engagement
- Analytics for investment performance

### 6.4 Admin Panel Integration
- Admin can view all investments
- Admin can manually trigger profit distribution
- Admin can manage investment disputes
- Admin can set platform fees

---

## 7. Security & Validation

### 7.1 Firestore Security Rules
```javascript
// investment_vehicles collection
match /investment_vehicles/{vehicleId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && 
                   request.resource.data.initiatorUserId == request.auth.uid;
  allow update: if request.auth != null && 
                   (resource.data.initiatorUserId == request.auth.uid || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
}

// investments collection
match /investments/{investmentId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
                   (resource.data.userId == request.auth.uid || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
}

// investment_transactions collection
match /investment_transactions/{transactionId} {
  allow read: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
                   (resource.data.userId == request.auth.uid || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
}
```

### 7.2 Validation Rules
- Minimum investment amount validation
- Maximum investment validation (not exceeding goal)
- Investment deadline validation
- Share price validation (reasonable range)
- Ownership validation (can't sell more than owned)
- Duplicate investment prevention

---

## 8. Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] Create data models
- [ ] Set up Firestore collections structure
- [ ] Implement basic services (CRUD operations)
- [ ] Create Firestore security rules
- [ ] Basic UI structure

### Phase 2: Investment Creation & Listing (Week 2-3)
- [ ] Investment creation page
- [ ] Investment listing page
- [ ] Investment detail page
- [ ] Integration with existing ad system

### Phase 3: Investment & Payment (Week 3-4)
- [ ] Investment form and validation
- [ ] Payment gateway integration
- [ ] Transaction processing
- [ ] Investment status updates

### Phase 4: Profit Distribution (Week 4-5)
- [ ] Profit calculation logic
- [ ] Automated profit distribution
- [ ] Profit history tracking
- [ ] Notification system

### Phase 5: Share Marketplace (Week 5-6)
- [ ] Share listing functionality
- [ ] Share marketplace page
- [ ] Share purchase flow
- [ ] Share transfer logic

### Phase 6: User Dashboard (Week 6-7)
- [ ] My investments page
- [ ] Investment detail view
- [ ] Transaction history
- [ ] Profit tracking

### Phase 7: Testing & Refinement (Week 7-8)
- [ ] Unit testing
- [ ] Integration testing
- [ ] UI/UX improvements
- [ ] Performance optimization
- [ ] Bug fixes

---

## 9. UI/UX Considerations

### 9.1 Visual Elements
- Progress bars for funding status
- Charts for profit visualization
- Investment timeline
- Investor avatars/list
- Vehicle images and 360 views

### 9.2 User Experience
- Clear investment terms display
- Real-time funding updates
- Easy investment process (minimal steps)
- Transparent profit calculations
- Clear share marketplace interface

### 9.3 Mobile Responsiveness
- Optimized for mobile devices
- Touch-friendly controls
- Responsive layouts
- Fast loading times

---

## 10. Future Enhancements

1. **Investment Analytics Dashboard**
   - ROI tracking
   - Performance metrics
   - Comparison tools

2. **Automated Investment Rules**
   - Auto-invest based on criteria
   - Investment alerts

3. **Investment Groups**
   - Group investments
   - Group profit sharing

4. **Vehicle Management**
   - Maintenance tracking
   - Rental income distribution
   - Insurance management

5. **Advanced Marketplace Features**
   - Share auctions
   - Price negotiation
   - Bulk share purchases

---

## 11. Technical Considerations

### 11.1 Performance
- Efficient Firestore queries (use indexes)
- Pagination for large lists
- Caching strategies
- Optimistic UI updates

### 11.2 Scalability
- Cloud Functions for heavy operations
- Batch operations for transactions
- Efficient data structure
- Proper indexing

### 11.3 Error Handling
- Payment failure handling
- Network error recovery
- Transaction rollback mechanisms
- User-friendly error messages

### 11.4 Data Consistency
- Use Firestore transactions for critical operations
- Implement idempotency for payments
- Proper validation before writes
- Audit trail for all financial operations

---

## 12. Testing Strategy

### 12.1 Unit Tests
- Model serialization/deserialization
- Service method logic
- Calculation functions (profit, ratios)

### 12.2 Integration Tests
- Investment creation flow
- Payment processing
- Profit distribution
- Share marketplace transactions

### 12.3 User Acceptance Tests
- End-to-end investment flow
- Share purchase flow
- Profit distribution verification

---

This plan provides a comprehensive structure for implementing the mutual investment feature. Each component can be developed incrementally, allowing for iterative testing and refinement.

