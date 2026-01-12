export interface Subscription {
    id: string; // uuid
    user_id: string; // uuid
    razorpay_subscription_id: string; // Razorpay subscription ID
    plan_id: string; // uuid - reference to plans table
    status: 'created' | 'authenticated' | 'active' | 'pending' | 'halted' | 'cancelled' | 'completed' | 'paused' | 'resumed';
    current_start: number | null; // Unix timestamp
    current_end: number | null; // Unix timestamp
    last_charged_at: number | null; // Unix timestamp - when subscription was last charged
    charge_at: number | null; // Unix timestamp - next charge date
    start_at: number | null; // Unix timestamp - subscription start date
    end_at: number | null; // Unix timestamp - subscription end date
    quantity: number;
    total_count: number; // Total billing cycles
    paid_count: number; // Number of successful payments
    created_at: string; // timestamp
    updated_at: string; // timestamp
}

