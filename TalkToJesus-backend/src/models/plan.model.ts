export interface Plan {
    id: string; // uuid
    name: string;
    price: number; // in paise (49900 for 499 Rs)
    razorpay_plan_id: string; // Razorpay plan ID
    interval: number; // Billing interval (e.g., 1 for monthly)
    period: 'daily' | 'weekly' | 'monthly' | 'yearly'; // Billing period
    cycles: number; // Total number of billing cycles (e.g., 12 for 12 months)
    is_prod: boolean; // true for production plans, false for development plans
    created_at: string; // timestamp
}
