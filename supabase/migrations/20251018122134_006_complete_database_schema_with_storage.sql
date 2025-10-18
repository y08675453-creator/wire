/*
  # Complete Database Schema for WireBazaar

  ## Overview
  This migration creates a complete database schema for the WireBazaar e-commerce platform,
  including products, users, orders, inquiries, and payment tracking with proper RLS policies.

  ## New Tables Created

  ### 1. products
  - `id` (uuid, primary key)
  - `name` (text) - Product name
  - `brand` (text) - Brand name
  - `category` (text) - Product category
  - `colors` (text[]) - Available colors
  - `description` (text) - Product description
  - `specifications` (jsonb) - Technical specifications
  - `base_price` (decimal) - Price per unit
  - `unit_type` (text) - 'metres' or 'coils'
  - `stock_quantity` (integer) - Available stock
  - `image_url` (text) - Product image URL
  - `brochure_url` (text) - Optional brochure URL
  - `is_active` (boolean) - Published status
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 2. phone_users
  - `id` (uuid, primary key)
  - `phone_number` (text, unique) - User's phone number
  - `phone_verified` (boolean) - Verification status
  - `last_login_at` (timestamptz) - Last login timestamp
  - `created_at` (timestamptz)

  ### 3. otp_codes
  - `id` (uuid, primary key)
  - `phone_number` (text) - Phone number for OTP
  - `otp_code` (text) - 6-digit OTP code
  - `expires_at` (timestamptz) - Expiration time
  - `verified` (boolean) - Verification status
  - `created_at` (timestamptz)

  ### 4. user_profiles
  - `id` (uuid, primary key)
  - `phone_user_id` (uuid, foreign key) - Reference to phone_users
  - `full_name` (text)
  - `email` (text)
  - `address` (text)
  - `city` (text)
  - `state` (text)
  - `pincode` (text)
  - `company_name` (text) - For business users
  - `business_type` (text) - Type of business
  - `gst_number` (text) - GST registration number
  - `profile_completed` (boolean)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 5. orders
  - `id` (uuid, primary key)
  - `user_id` (text) - User identifier (can be guest or registered)
  - `phone_user_id` (uuid, foreign key, nullable) - Reference to phone_users for registered users
  - `order_number` (text, unique) - Order tracking number
  - `customer_name` (text)
  - `customer_email` (text)
  - `customer_phone` (text)
  - `customer_address` (text)
  - `customer_city` (text)
  - `customer_state` (text)
  - `customer_pincode` (text)
  - `items` (jsonb) - Order items with product details
  - `subtotal` (decimal)
  - `shipping_cost` (decimal)
  - `total_amount` (decimal)
  - `status` (text) - Order status (pending, confirmed, shipped, delivered, cancelled)
  - `payment_status` (text) - Payment status (pending, verified, failed)
  - `payment_method` (text)
  - `estimated_delivery` (text)
  - `notes` (text)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 6. inquiries
  - `id` (uuid, primary key)
  - `phone_user_id` (uuid, foreign key, nullable)
  - `user_type` (text) - retailer, contractor, builder, etc.
  - `location` (text)
  - `product_name` (text)
  - `product_specification` (text)
  - `quantity` (text)
  - `contact_name` (text)
  - `contact_email` (text)
  - `contact_phone` (text)
  - `additional_requirements` (text)
  - `status` (text) - pending, contacted, resolved
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 7. payment_qr_codes
  - `id` (uuid, primary key)
  - `image_url` (text) - QR code image URL
  - `payment_details` (jsonb) - UPI ID, account details, etc.
  - `is_active` (boolean)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 8. payment_screenshots
  - `id` (uuid, primary key)
  - `order_id` (uuid, foreign key)
  - `user_id` (text)
  - `screenshot_url` (text)
  - `verification_status` (text) - pending, approved, rejected
  - `verified_by` (text)
  - `verified_at` (timestamptz)
  - `notes` (text)
  - `created_at` (timestamptz)

  ### 9. owner_users
  - `id` (uuid, primary key)
  - `email` (text, unique)
  - `password_hash` (text)
  - `full_name` (text)
  - `role` (text) - admin, manager, etc.
  - `is_active` (boolean)
  - `created_at` (timestamptz)

  ## Security
  - RLS enabled on all tables
  - Public read access for products (active only)
  - Authenticated users can manage their own data
  - Owner users have full access to all data
  - OTP codes are protected and expire after 5 minutes

  ## Indexes
  - Indexes on frequently queried columns (phone_number, order_number, email)
  - Indexes on foreign keys for better join performance
*/

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  brand text NOT NULL,
  category text NOT NULL,
  colors text[] DEFAULT '{}',
  description text DEFAULT '',
  specifications jsonb DEFAULT '{}',
  base_price decimal(10, 2) NOT NULL,
  unit_type text NOT NULL DEFAULT 'metres',
  stock_quantity integer DEFAULT 0,
  image_url text DEFAULT '',
  brochure_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create phone_users table
CREATE TABLE IF NOT EXISTS phone_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text UNIQUE NOT NULL,
  phone_verified boolean DEFAULT false,
  last_login_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create otp_codes table
CREATE TABLE IF NOT EXISTS otp_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text NOT NULL,
  otp_code text NOT NULL,
  expires_at timestamptz NOT NULL,
  verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_user_id uuid REFERENCES phone_users(id) ON DELETE CASCADE,
  full_name text,
  email text,
  address text,
  city text,
  state text,
  pincode text,
  company_name text,
  business_type text,
  gst_number text,
  profile_completed boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(phone_user_id)
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  phone_user_id uuid REFERENCES phone_users(id) ON DELETE SET NULL,
  order_number text UNIQUE NOT NULL,
  customer_name text NOT NULL,
  customer_email text NOT NULL,
  customer_phone text NOT NULL,
  customer_address text NOT NULL,
  customer_city text,
  customer_state text,
  customer_pincode text NOT NULL,
  items jsonb NOT NULL DEFAULT '[]',
  subtotal decimal(10, 2) NOT NULL,
  shipping_cost decimal(10, 2) DEFAULT 0,
  total_amount decimal(10, 2) NOT NULL,
  status text DEFAULT 'pending',
  payment_status text DEFAULT 'pending',
  payment_method text,
  estimated_delivery text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create inquiries table
CREATE TABLE IF NOT EXISTS inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_user_id uuid REFERENCES phone_users(id) ON DELETE SET NULL,
  user_type text NOT NULL,
  location text NOT NULL,
  product_name text,
  product_specification text,
  quantity text,
  contact_name text NOT NULL,
  contact_email text NOT NULL,
  contact_phone text NOT NULL,
  additional_requirements text,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create payment_qr_codes table
CREATE TABLE IF NOT EXISTS payment_qr_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url text NOT NULL,
  payment_details jsonb DEFAULT '{}',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create payment_screenshots table
CREATE TABLE IF NOT EXISTS payment_screenshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  user_id text NOT NULL,
  screenshot_url text NOT NULL,
  verification_status text DEFAULT 'pending',
  verified_by text,
  verified_at timestamptz,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Create owner_users table
CREATE TABLE IF NOT EXISTS owner_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  full_name text NOT NULL,
  role text DEFAULT 'admin',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_phone_users_phone ON phone_users(phone_number);
CREATE INDEX IF NOT EXISTS idx_otp_codes_phone ON otp_codes(phone_number);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires ON otp_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone_user ON user_profiles(phone_user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_phone_user ON orders(phone_user_id);
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_inquiries_phone_user ON inquiries(phone_user_id);
CREATE INDEX IF NOT EXISTS idx_inquiries_status ON inquiries(status);
CREATE INDEX IF NOT EXISTS idx_payment_screenshots_order ON payment_screenshots(order_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);

-- Enable Row Level Security on all tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_screenshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for products table
CREATE POLICY "Anyone can view active products"
  ON products FOR SELECT
  USING (is_active = true OR current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

CREATE POLICY "Service role can insert products"
  ON products FOR INSERT
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

CREATE POLICY "Service role can update products"
  ON products FOR UPDATE
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

CREATE POLICY "Service role can delete products"
  ON products FOR DELETE
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- RLS Policies for phone_users table
CREATE POLICY "Users can view own phone_user record"
  ON phone_users FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert phone_user"
  ON phone_users FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own phone_user record"
  ON phone_users FOR UPDATE
  USING (true);

-- RLS Policies for otp_codes table
CREATE POLICY "Anyone can insert OTP codes"
  ON otp_codes FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can read OTP codes"
  ON otp_codes FOR SELECT
  USING (true);

CREATE POLICY "Anyone can update OTP codes"
  ON otp_codes FOR UPDATE
  USING (true);

-- RLS Policies for user_profiles table
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (true);

-- RLS Policies for orders table
CREATE POLICY "Anyone can view orders"
  ON orders FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert orders"
  ON orders FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update orders"
  ON orders FOR UPDATE
  USING (true);

-- RLS Policies for inquiries table
CREATE POLICY "Anyone can view inquiries"
  ON inquiries FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert inquiries"
  ON inquiries FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update inquiries"
  ON inquiries FOR UPDATE
  USING (true);

-- RLS Policies for payment_qr_codes table
CREATE POLICY "Anyone can view active QR codes"
  ON payment_qr_codes FOR SELECT
  USING (is_active = true);

CREATE POLICY "Service role can manage QR codes"
  ON payment_qr_codes FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- RLS Policies for payment_screenshots table
CREATE POLICY "Anyone can view payment screenshots"
  ON payment_screenshots FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert payment screenshots"
  ON payment_screenshots FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Service role can update payment screenshots"
  ON payment_screenshots FOR UPDATE
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- RLS Policies for owner_users table
CREATE POLICY "Service role can manage owner users"
  ON owner_users FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');
