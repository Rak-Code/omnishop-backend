-- Create database
CREATE DATABASE IF NOT EXISTS `omnishop_db`
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
USE `omnishop_db`;

-- PRODUCTS
CREATE TABLE `product` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sku` VARCHAR(64) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `price` DECIMAL(13,2) NOT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_product_sku` (`sku`),
  KEY `idx_product_name` (`name`),
  KEY `idx_product_price` (`price`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- WAREHOUSES
CREATE TABLE `warehouse` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `location` VARCHAR(255) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_warehouse_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- INVENTORY: per product per warehouse (optimistic locking)
CREATE TABLE `inventory` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `warehouse_id` BIGINT UNSIGNED NOT NULL,
  `quantity_available` INT NOT NULL DEFAULT 0,      -- units physically available
  `reserved_quantity` INT NOT NULL DEFAULT 0,       -- units reserved for orders
  `version` BIGINT UNSIGNED NOT NULL DEFAULT 0,     -- optimistic lock (JPA @Version)
  `last_updated` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  CONSTRAINT `ux_inventory_product_warehouse` UNIQUE (`product_id`,`warehouse_id`),
  CONSTRAINT `fk_inventory_product` FOREIGN KEY (`product_id`) REFERENCES `product`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_inventory_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouse`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY `idx_inventory_product` (`product_id`),
  KEY `idx_inventory_warehouse` (`warehouse_id`),
  KEY `idx_inventory_product_warehouse` (`product_id`,`warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- CUSTOMERS (minimal)
CREATE TABLE `customer` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(120) NOT NULL,
  `last_name` VARCHAR(120) NULL,
  `email` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(32) NULL,
  `password_hash` VARCHAR(255) NULL,   -- stored when security implemented (BCrypt)
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_customer_email` (`email`),
  KEY `idx_customer_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ORDERS (header)
CREATE TABLE `orders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `total_amount` DECIMAL(13,2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'USD',
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- 1=PLACED,2=CONFIRMED,3=SHIPPED,4=DELIVERED,5=CANCELLED,6=EXPIRED
  `idempotency_key_id` BIGINT UNSIGNED NULL,     -- optional FK to idempotency_key
  `reservation_expires_at` DATETIME(6) NULL,     -- when reserved stock expires
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customer`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_orders_idempotency` FOREIGN KEY (`idempotency_key_id`) REFERENCES `idempotency_key`(`id`) ON UPDATE CASCADE ON DELETE SET NULL,
  KEY `idx_orders_customer_created` (`customer_id`,`created_at`),
  KEY `idx_orders_status_created` (`status`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ORDER LINES (each product in an order)
CREATE TABLE `order_line` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `warehouse_id` BIGINT UNSIGNED NOT NULL,
  `unit_price` DECIMAL(13,2) NOT NULL,
  `quantity` INT NOT NULL,
  `line_total` DECIMAL(13,2) AS (`unit_price` * `quantity`) STORED,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_orderline_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `fk_orderline_product` FOREIGN KEY (`product_id`) REFERENCES `product`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_orderline_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouse`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY `idx_orderline_order` (`order_id`),
  KEY `idx_orderline_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- IDEMPOTENCY KEY table (for safe retries)
CREATE TABLE `idempotency_key` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `key_value` VARCHAR(128) NOT NULL,          -- the client-provided Idempotency-Key
  `request_hash` CHAR(64) NULL,               -- optional hash of request body for sanity check
  `response_reference` VARCHAR(255) NULL,     -- optional pointer to created resource (e.g., order id)
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `expires_at` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_idempotency_key_value` (`key_value`),
  KEY `idx_idempotency_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Indexes

CREATE UNIQUE INDEX ux_product_sku ON product (sku);
CREATE INDEX idx_product_name ON product (name);
CREATE INDEX idx_product_price ON product (price);
CREATE UNIQUE INDEX ux_warehouse_name ON warehouse (name);
CREATE UNIQUE INDEX ux_inventory_product_warehouse ON inventory (product_id, warehouse_id);
CREATE INDEX idx_inventory_product ON inventory (product_id);
CREATE INDEX idx_inventory_warehouse ON inventory (warehouse_id);
CREATE UNIQUE INDEX ux_customer_email ON customer (email);
CREATE INDEX idx_orders_status_expires ON orders (status, reservation_expires_at);
CREATE UNIQUE INDEX ux_idempotency_key_value ON idempotency_key (key_value);
CREATE INDEX idx_idempotency_expires ON idempotency_key (expires_at);

-- End of omnishop.sql
