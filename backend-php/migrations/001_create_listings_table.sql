-- Migration: Create listings table
CREATE TABLE listings (
    id VARCHAR(255) PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    area DECIMAL(10,2) NOT NULL,
    country ENUM('saudiArabia', 'uae', 'qatar', 'bahrain', 'oman', 'kuwait') NOT NULL,
    location VARCHAR(200) NOT NULL,
    image_urls JSON NOT NULL,
    is_featured BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);