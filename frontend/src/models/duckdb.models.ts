// Domain models for DuckDB entities

export interface User {
  id: number;
  name: string;
  email: string;
  age: number;
  created_at: string;
  role?: string;
  status?: 'active' | 'inactive' | 'pending';
}

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  stock: number;
  category: string;
  created_at: string;
}

export interface Order {
  id: number;
  user_id: number;
  user_name: string;
  items: OrderItem[];
  total: number;
  status: 'pending' | 'completed' | 'shipped' | 'cancelled';
  created_at: string;
}

export interface OrderItem {
  product_id: number;
  product_name: string;
  quantity: number;
  price: number;
}

export interface UserStats {
  total_users: number;
  today_count: number;
  unique_domains: number;
}

export interface ProductStats {
  total_products: number;
  total_value: number;
  low_stock_count: number;
}

export interface OrderStats {
  total_orders: number;
  pending_orders: number;
  total_revenue: number;
}
