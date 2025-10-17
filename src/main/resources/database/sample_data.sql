

-- Insert Products
INSERT INTO `product` (`sku`, `name`, `description`, `price`, `is_active`) VALUES
('NBK-001', 'Wireless Mechanical Keyboard', 'Tenkeyless mechanical keyboard with RGB lighting and Bluetooth 5.0', 89.99, 1),
('GMS-002', 'Gaming Mouse', 'High-precision gaming mouse with 16000 DPI and customizable weights', 49.99, 1);

-- Insert Warehouses
INSERT INTO `warehouse` (`name`, `location`) VALUES
('Main Warehouse', '123 Industrial Ave, Tech City, TC 10101'),
('West Coast DC', '456 Commerce St, Digital Valley, DV 20202');

-- Insert Inventory
INSERT INTO `inventory` (`product_id`, `warehouse_id`, `quantity_available`, `reserved_quantity`, `version`) VALUES
(1, 1, 150, 25, 1),
(1, 2, 75, 10, 1),
(2, 1, 200, 30, 1),
(2, 2, 100, 15, 1);

-- Insert Customers
INSERT INTO `customer` (`first_name`, `last_name`, `email`, `phone`) VALUES
('John', 'Smith', 'john.smith@email.com', '+1-555-0101'),
('Sarah', 'Johnson', 'sarah.j@email.com', '+1-555-0102');

-- Insert Idempotency Keys
INSERT INTO `idempotency_key` (`key_value`, `request_hash`, `response_reference`, `expires_at`) VALUES
('order_create_abc123xyz', 'a1b2c3d4e5f6g7h8', 'ORD-001', DATE_ADD(NOW(), INTERVAL 1 HOUR)),
('order_create_def456uvw', 'i9j8k7l6m5n4o3p2', 'ORD-002', DATE_ADD(NOW(), INTERVAL 1 HOUR));

-- Insert Orders
INSERT INTO `orders` (`customer_id`, `total_amount`, `currency`, `status`, `idempotency_key_id`, `reservation_expires_at`) VALUES
(1, 229.97, 'USD', 1, 1, DATE_ADD(NOW(), INTERVAL 30 MINUTE)),
(2, 49.99, 'USD', 2, 2, NULL);

-- Insert Order Lines
INSERT INTO `order_line` (`order_id`, `product_id`, `warehouse_id`, `unit_price`, `quantity`) VALUES
(1, 1, 1, 89.99, 2),   -- 2 keyboards from main warehouse
(1, 2, 1, 49.99, 1),   -- 1 mouse from main warehouse
(2, 2, 2, 49.99, 1);   -- 1 mouse from west coast warehouse