CREATE DATABASE IF NOT EXISTS amazon_analysis
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE amazon_analysis;

CREATE TABLE products (
  product_id          VARCHAR(20) PRIMARY KEY,
  product_name        TEXT,
  category            TEXT,
  main_category       VARCHAR(60),
  sub_category        VARCHAR(100),
  leaf_category       VARCHAR(100),
  category_group      VARCHAR(30),
  discounted_price    DECIMAL(10,2),
  actual_price        DECIMAL(10,2),
  discount_pct        DECIMAL(5,1),
  rating              DECIMAL(2,1) NULL,
  rating_count        INT NULL,
  adj_rating          DECIMAL(5,3) NULL,
  rating_reliability  VARCHAR(20),
  price_bucket        VARCHAR(20),
  price_vs_subcat     DECIMAL(8,2),
  value_score         DECIMAL(5,1) NULL,
  rating_missing      BOOLEAN,
  count_missing       BOOLEAN,
  titles_usable       BOOLEAN,
  variant_group       VARCHAR(20),
  variant_group_size  INT,
  is_primary_listing  BOOLEAN,
  about_product       TEXT,
  img_link            TEXT,
  product_link        TEXT
);

CREATE TABLE reviews (
  review_id     VARCHAR(30) PRIMARY KEY,
  user_id       VARCHAR(40),
  user_name     VARCHAR(255),
  review_title  TEXT
);

CREATE TABLE product_reviews (
  product_id VARCHAR(20),
  review_id  VARCHAR(30),
  PRIMARY KEY (product_id, review_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  FOREIGN KEY (review_id)  REFERENCES reviews(review_id)
);
