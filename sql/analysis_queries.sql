USE amazon_analysis;

-- Q0: Integrity check: reviews shared across variant listings (expect 759)
SELECT COUNT(*) AS shared_reviews
FROM (SELECT review_id FROM product_reviews GROUP BY review_id HAVING COUNT(*) > 1) t;

-- Q1: Discount, rating and volume by category (distinct listings only)
SELECT category_group, COUNT(*) AS listings,
       ROUND(AVG(discount_pct), 1) AS avg_discount,
       ROUND(AVG(rating), 2) AS avg_rating,
       ROUND(AVG(adj_rating), 2) AS avg_adj_rating,
       SUM(rating_count) AS total_ratings
FROM products
WHERE is_primary_listing = 1
GROUP BY category_group
ORDER BY avg_discount DESC;

-- Q2: Top 3 listings per category by rating count (ROW_NUMBER: ties get distinct ranks)
WITH ranked AS (
  SELECT category_group, product_name, rating, rating_count,
         ROW_NUMBER() OVER (PARTITION BY category_group ORDER BY rating_count DESC) AS rn
  FROM products
  WHERE is_primary_listing = 1 AND rating_count IS NOT NULL
)
SELECT category_group, rn, product_name, rating, rating_count
FROM ranked WHERE rn <= 3 ORDER BY category_group, rn;

-- Q3: Products priced above their leaf-category average (leaf groups of 5+ only).
-- Sub-category was too coarse (ACs compared with small heaters); mean is skewed by premium items.
WITH leaf_avg AS (
  SELECT leaf_category, COUNT(*) AS n, AVG(discounted_price) AS avg_price
  FROM products WHERE is_primary_listing = 1
  GROUP BY leaf_category HAVING COUNT(*) >= 5
)
SELECT p.product_name, p.leaf_category, p.discounted_price,
       ROUND(l.avg_price, 0) AS leaf_avg, l.n AS leaf_size,
       ROUND(p.discounted_price / l.avg_price, 2) AS times_avg
FROM products p
JOIN leaf_avg l ON p.leaf_category = l.leaf_category
WHERE p.is_primary_listing = 1 AND p.discounted_price > l.avg_price
ORDER BY times_avg DESC LIMIT 15;

-- Q4: High rating (4.5+) but under 100 ratings: unreliable scores
SELECT product_id, product_name, rating, rating_count, ROUND(adj_rating, 2) AS adj_rating
FROM products
WHERE rating >= 4.5 AND rating_count < 100 AND is_primary_listing = 1
ORDER BY rating_count;

-- Q5: Reviews held per product (dataset holds a sample of up to 8 per product)
SELECT reviews_in_data, COUNT(*) AS products
FROM (SELECT p.product_id, COUNT(pr.review_id) AS reviews_in_data
      FROM products p LEFT JOIN product_reviews pr ON p.product_id = pr.product_id
      GROUP BY p.product_id) t
GROUP BY reviews_in_data ORDER BY reviews_in_data;

-- Q6: Discount band vs rating
SELECT CASE WHEN discount_pct < 20 THEN '1) 0-19%'
            WHEN discount_pct < 40 THEN '2) 20-39%'
            WHEN discount_pct < 60 THEN '3) 40-59%'
            WHEN discount_pct < 80 THEN '4) 60-79%'
            ELSE '5) 80%+' END AS discount_band,
       COUNT(*) AS listings, ROUND(AVG(rating), 2) AS avg_rating,
       ROUND(AVG(adj_rating), 2) AS avg_adj_rating,
       ROUND(AVG(rating_count), 0) AS avg_ratings_per_listing
FROM products
WHERE is_primary_listing = 1
GROUP BY discount_band ORDER BY discount_band;

-- Q7: Price bucket vs popularity (rating_count as a proxy for sales)
SELECT price_bucket, COUNT(*) AS listings, SUM(rating_count) AS total_ratings,
       ROUND(AVG(rating_count), 0) AS avg_ratings_per_listing, ROUND(AVG(rating), 2) AS avg_rating
FROM products
WHERE is_primary_listing = 1
GROUP BY price_bucket ORDER BY MIN(discounted_price);

-- Q8: Top 3 value-score listings per category (RANK: ties share a rank)
WITH ranked AS (
  SELECT category_group, product_name, discounted_price, discount_pct,
         ROUND(adj_rating, 2) AS adj_rating, value_score,
         RANK() OVER (PARTITION BY category_group ORDER BY value_score DESC) AS rnk
  FROM products
  WHERE is_primary_listing = 1 AND value_score IS NOT NULL
)
SELECT * FROM ranked WHERE rnk <= 3 ORDER BY category_group, rnk;